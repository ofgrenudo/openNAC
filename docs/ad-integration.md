---
title: AD integration
nav_order: 3
---

# AD integration (dev stand-in and going to production)

802.1X with PEAP-MSCHAPv2 needs the user's NT password hash, which AD does not
hand out over a plain LDAP bind. FreeRADIUS gets it by calling `ntlm_auth`,
which only **Winbind** provides — so the RADIUS host must be joined to the
domain, same as a real deployment.

## Dev domain

`docker-compose.yml` runs a throwaway AD domain controller (`dc`, the
`nowsci/samba-domain` image) that `freeradius` joins on startup
(`docker/freeradius/entrypoint.sh`). Set `AD_DOMAIN` (default
`DEV.OPENNAC.LOCAL`) and `AD_ADMIN_PASSWORD` in `.env`, then:

```sh
docker compose up -d
```

The join only happens once; the result is persisted in the `freeradius-samba`
volume. For that to actually survive a restart, `freeradius` has a pinned
`hostname:` in `docker-compose.yml` — Samba's computer account is named after
the container's hostname, so a random one (Docker's default) would silently
orphan the persisted join on every recreate. Inside the `freeradius`
container:

```sh
wbinfo -t         # confirm the trust to the domain
wbinfo -u         # list domain users
```

Create a test user on the `dc` container:

```sh
docker compose exec dc samba-tool user create testuser 'Pa55word123!'
```

Then test the NT-hash path directly (`ntlm_auth --username=... --password=...
--domain=...`), and finally through RADIUS with `radtest -t mschap`.

**Dev DC's NTLM policy:** Samba AD DCs default to rejecting legacy NTLMv1
(what MS-CHAPv1's response is, cryptographically), which made `radtest -t
mschap` fail with a correctly-computed response. The dev `dc` sets
`ntlm auth = yes` (in both `/etc/samba/smb.conf` and the persisted
`/etc/samba/external/smb.conf`) to allow it for testing. A real AD likely
restricts this the same way — `ntlm auth = mschapv2-and-ntlmv2-only` allows
MSCHAPv2 specifically while still blocking plain NTLMv1/v2, which is what
production should actually use once PEAP-MSCHAPv2 is wired up (tracked in
[issue #3](https://github.com/ofgrenudo/openNAC/issues/3)).

## Going to the real workplace AD

Nothing in `docker/freeradius/Dockerfile`, `entrypoint.sh` or `mschap` is dev
specific — they just join whatever domain `AD_DOMAIN`/`AD_ADMIN_PASSWORD`
point at. To go to production:

1. Stop running the `dc` service (it's a stand-in only).
2. Point `freeradius` at the real DC's DNS instead of `dc` — either put the
   container on a network that already resolves the domain, or change the
   `DC_IP` lookup in `entrypoint.sh` to the real DC's address.
3. Set `AD_DOMAIN` to the real realm and `AD_ADMIN_PASSWORD` to a real
   domain-join account's credentials (ideally one scoped to just joining
   computers, not a full admin).
4. Clear the `freeradius-samba` volume so it re-joins the new domain.

## Alternative: realmd

Ops who prefer `realmd`'s discovery over raw `net ads join` can use it
instead, as long as it's told to use Winbind rather than its default `sssd`
backend — `sssd` doesn't ship `ntlm_auth`, which `rlm_mschap` needs:

```sh
realm join --client-software=winbind "$AD_DOMAIN" -U administrator
```

Everything downstream (`winbindd`, `ntlm_auth`, the `mschap` module config)
is the same either way.

See [pluggable-backends.md](pluggable-backends.md) for how this fits
alongside the Postgres backend and other identity sources, and
[the roadmap issue](https://github.com/ofgrenudo/openNAC/issues/3) for what's
still open (PEAP wrapping, the `registered_devices` VLAN lookup, EAP-TLS).
