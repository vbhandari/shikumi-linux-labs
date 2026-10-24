# firewalld: Fedora / RHEL-family alternate path

```bash
sudo firewall-cmd --state
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --add-port=8010/tcp            # runtime only
sudo firewall-cmd --reload                       # undo runtime changes
sudo firewall-cmd --permanent --add-service=http # persistent
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
sudo nft list ruleset | grep -m3 firewalld       # firewalld writes nft rules
```

Lab 11.3 (to verify): put `veth-host` in the `trusted` zone and enable masquerade on the uplink's zone.

```bash
sudo firewall-cmd --zone=trusted --add-interface=veth-host
sudo firewall-cmd --zone="$(firewall-cmd --get-default-zone)" --add-masquerade
```
