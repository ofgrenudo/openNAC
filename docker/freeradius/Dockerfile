# FreeRADIUS for openNAC
# Build: docker build -t opennac-freeradius docker/freeradius
# Run:   docker run --rm -p 1812:1812/udp -p 1813:1813/udp \
#          -v "$PWD/docker/freeradius/raddb:/etc/freeradius" opennac-freeradius -X
FROM freeradius/freeradius-server:latest

# SQL backend for the registered_devices lookup (Postgres, per docs/OUTLINE.md),
# LDAP for AD/Entra, and Winbind for the MSCHAPv2-against-AD path (see
# docs/ad-integration.md). Already present in some image variants; a no-op then.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      freeradius-postgresql freeradius-ldap \
      winbind samba-common-bin krb5-user \
 && rm -rf /var/lib/apt/lists/*

COPY sql /etc/freeradius/mods-available/sql
RUN ln -s ../mods-available/sql /etc/freeradius/mods-enabled/sql

COPY mschap /etc/freeradius/mods-available/mschap

# ntlm_auth talks to winbindd over a socket only root/winbindd_priv can read;
# radiusd runs as freerad, so it needs to be in that group too.
RUN usermod -aG winbindd_priv freerad

COPY entrypoint.sh /opennac-entrypoint.sh
RUN chmod +x /opennac-entrypoint.sh
ENTRYPOINT ["/opennac-entrypoint.sh"]

# 1812 auth, 1813 accounting, 3799 CoA/Disconnect (used for re-auth after registration)
EXPOSE 1812/udp 1813/udp 3799/udp

# entrypoint.sh joins the AD domain (if AD_DOMAIN is set) then execs the
# image's own entrypoint; pass -X for debug output.
