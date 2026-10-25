# ufw commands used in the course (Ubuntu)

Always allow SSH before enabling ufw, and arm an automatic undo first.

```bash
sudo systemd-run --on-active=10min --unit shikumi-ufw-revert ufw disable
sudo ufw allow OpenSSH
sudo ufw --force enable
sudo ufw status verbose
sudo systemctl stop shikumi-ufw-revert.timer   # once you are sure SSH still works
```

| Lab | Rule |
|---|---|
| 11.1 | `sudo ufw allow 8010/tcp`, `sudo ufw allow 8011/tcp` (8011 is then dropped by our nft table) |
| 11.3 | `sudo ufw route allow in on veth-host out on "$UPLINK"` |
| 12.1 | `sudo ufw allow 80/tcp` |
| 12.2 | `sudo ufw allow 443/tcp` |

On a cloud VM, ufw is not your only firewall: keep the provider's firewall (Hetzner Cloud Firewall, AWS security group) in front, allowing inbound SSH from your own IP only (Lab 0.1). Each `ufw allow` above opens its port to the whole internet unless that firewall stops it. For a host test, add the port there from your own IP only, and remove it afterwards.

ufw's forward policy is DROP by default (`/etc/default/ufw`), which is why Lab 11.3 needs a route rule.
