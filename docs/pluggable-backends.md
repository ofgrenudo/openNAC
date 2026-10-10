---
title: Pluggable backends
nav_order: 4
---

# Pluggable backends

openNAC needs to work against whatever identity/device system an
organization already runs: AD, Entra, a plain database, LDAP, something
else. We don't build our own plugin layer for that — FreeRADIUS already has
one. A backend is a **module**, and swapping or adding one is config, not
code:

1. A module config file in `mods-available/<name>` (the module's settings —
   where it connects, how it maps fields).
2. A symlink for it in `mods-enabled/`.
3. A reference to it in `sites-available/default`, in the `authorize` and/or
   `authenticate` section, usually already present as a disabled line
   (`-sql`, `-ldap`, …) waiting to be turned on.

## Worked examples in this repo

- **`sql`** (`docker/freeradius/sql`) — Postgres, used for the
  `registered_devices` lookup and RADIUS accounting tables. Connection
  details come from environment variables (`DB_HOST`, `DB_USER`, …), set in
  `docker-compose.yml`.
- **`mschap`** (`docker/freeradius/mschap`) — delegates the AD password check
  to Winbind's `ntlm_auth`. See [ad-integration.md](ad-integration.md).

Both are plain config files copied into the image by
`docker/freeradius/Dockerfile` — no application code.

## Other enterprise systems

FreeRADIUS ships modules for most of what else comes up:

- **`rlm_ldap`** — any LDAP directory, including Entra ID via Entra Domain
  Services or AD DS, or a non-AD LDAP server.
- **`rlm_rest`** — call out to an HTTP API (e.g. a custom identity service)
  for authorization decisions.
- **`rlm_python3`** — arbitrary custom logic when nothing else fits.
- **`rlm_radius`** — proxy to another RADIUS server (e.g. an existing NPS),
  useful when migrating rather than replacing.

Adding support for a new enterprise system means writing one of these module
configs, not extending openNAC's own code.
