# FreeRADIUS for openNAC
# Build: docker build -t opennac-freeradius docker/freeradius
# Run:   docker run --rm -p 1812:1812/udp -p 1813:1813/udp \
#          -v "$PWD/docker/freeradius/raddb:/etc/freeradius" opennac-freeradius -X
FROM freeradius/freeradius-server:latest

# SQL backend for the registered_devices lookup (Postgres, per docs/OUTLINE.md),
# and LDAP for AD. Already present in some image variants; this is a no-op then.
RUN apt-get update \
 && apt-get install -y --no-install-recommends freeradius-postgresql freeradius-ldap \
 && rm -rf /var/lib/apt/lists/*

# 1812 auth, 1813 accounting, 3799 CoA/Disconnect (used for re-auth after registration)
EXPOSE 1812/udp 1813/udp 3799/udp

# Image entrypoint runs radiusd; pass -X for debug output.
