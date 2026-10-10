#!/bin/sh
# Joins the AD domain (if AD_DOMAIN is set) before starting FreeRADIUS, so
# rlm_mschap's ntlm_auth has a working Winbind to call.
# shortcut: smb.conf/krb5.conf are regenerated on every start (cheap, idempotent);
# only the join itself is skipped on restart, via the secrets.tdb check below.
set -e

if [ -n "$AD_DOMAIN" ]; then
  REALM=$(echo "$AD_DOMAIN" | tr '[:lower:]' '[:upper:]')
  WORKGROUP=$(echo "$REALM" | cut -d. -f1)

  # The domain's SRV/A records live on the DC's own DNS, not Docker's embedded
  # resolver. Point resolution at it so `net ads join` can find the domain.
  # shortcut: assumes a compose service literally named "dc"; point this at the
  # real DC's DNS server/IP when deploying against the workplace AD instead.
  DC_IP=$(getent hosts dc | awk '{print $1}')
  if [ -n "$DC_IP" ]; then
    echo "nameserver $DC_IP" > /etc/resolv.conf
  fi

  cat > /etc/krb5.conf <<EOF
[libdefaults]
	default_realm = ${REALM}
	dns_lookup_realm = false
	dns_lookup_kdc = true
EOF

  cat > /etc/samba/smb.conf <<EOF
[global]
	workgroup = ${WORKGROUP}
	realm = ${REALM}
	security = ads
	winbind use default domain = yes
	idmap config * : backend = tdb
	idmap config * : range = 10000-999999
EOF

  if [ ! -f /var/lib/samba/private/secrets.tdb ]; then
    net ads join -U "administrator%${AD_ADMIN_PASSWORD}"
  fi
  winbindd

  # Clients (and radtest) rarely send a domain-qualified username; mschap
  # falls back to this NetBIOS name when %{mschap:NT-Domain} is empty.
  sed -i "s/__WORKGROUP__/${WORKGROUP}/" /etc/freeradius/mods-available/mschap
fi

exec /docker-entrypoint.sh "$@"
