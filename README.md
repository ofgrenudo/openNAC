# openNAC
Opensource Network Access Control


The idea here, is to provide a way to do 802.1x for wired + wireless. With a secondary check which essentially is MAB.

## Inner workings

Doing a 802.1x with WPA2/WPA3-Enterprise means that the AP is going to send the clients MAC in `Calling-Station-Id` on every 802.1X request. Essentially, we will configure freeRADIUS to do the following

1. Authenticates the user with 802.1X (PEAP-MSCHAPv2 against AD, or EAP-TLS).
2. In post-auth, looks up whether that MAC is registered.
3. Returns the trusted VLAN if it is, or the standard VLAN if it isn’t.

## Roadmap

- [ ] MAB (MAC Authentication Bypass)
- [ ] 802.1X
- [ ] PANA

###
