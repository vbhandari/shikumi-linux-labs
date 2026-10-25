# Lab 5.3: Sandbox the service and bind port 80

**Module M05 · systemd and the journal** · about 25 min · [Lab index](../../README.md#lab-index)

**Goal:** Score the unit's exposure, harden it, break a write path and read the error, let it bind port 80 with one capability, then put it back on 8000.

## Before you start

- Lab 5.2 done.
- Port 80 free (Lab 4.1).

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/port80.conf`](files/port80.conf)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/05.3-sandboxing/setup.sh
cd ~/labs/5.3
```

### Step 1: Score the unit as it is.

```bash
systemd-analyze security shikumi-api.service --no-pager | tail -n 1
systemd-analyze security shikumi-api.service --no-pager | head -n 25
```

### Step 2: Read the hardening drop-in, install it, and score again.

```bash
cat ~/shikumi-linux-labs/units/hardening.conf
sudo install -D -m 0644 ~/shikumi-linux-labs/units/hardening.conf /etc/systemd/system/shikumi-api.service.d/hardening.conf
sudo systemctl daemon-reload && sudo systemctl restart shikumi-api
systemd-analyze security shikumi-api.service --no-pager | tail -n 1
curl -s 'http://127.0.0.1:8000/data?name=hello.txt'; echo
```

The score should fall from about 9 (UNSAFE) to about 2 (OK). `ProtectSystem=strict` makes the whole filesystem read-only for the service, except the directories systemd creates for it (`StateDirectory=`, `CacheDirectory=`).

### Step 3: Point the cache at a read-only path and read the error.

```bash
printf 'SHIKUMI_CACHE=1\nSHIKUMI_CACHE_DIR=/etc/shikumi/cache\n' | sudo tee -a /etc/shikumi/shikumi-api.env
sudo systemctl restart shikumi-api
curl -s 'http://127.0.0.1:8000/data?name=hello.txt'; echo
sudo journalctl -u shikumi-api -n 3 --no-pager
```

The app answers 500 with `OSError: [Errno 30] Read-only file system`. Permissions allow root-owned `/etc`, but the sandbox does not.

### Step 4: Use the cache directory systemd made for you instead.

```bash
sudo sed -i '/^SHIKUMI_CACHE_DIR=/d' /etc/shikumi/shikumi-api.env
sudo systemctl restart shikumi-api
curl -s 'http://127.0.0.1:8000/data?name=hello.txt'; echo
ls -l /var/cache/shikumi
sudo sed -i '/^SHIKUMI_CACHE=/d' /etc/shikumi/shikumi-api.env
sudo systemctl restart shikumi-api
```

systemd passes the path in `CACHE_DIRECTORY`, and the app uses it. Lab 6.2 turns the cache on again under AppArmor.

### Step 5: Bind port 80 with one capability.

```bash
sudo install -m 0644 port80.conf /etc/systemd/system/shikumi-api.service.d/port80.conf
sudo systemctl daemon-reload && sudo systemctl restart shikumi-api
curl -s http://127.0.0.1/healthz; echo
grep Cap /proc/"$(systemctl show -p MainPID --value shikumi-api)"/status
systemctl show -p AmbientCapabilities,CapabilityBoundingSet shikumi-api
```

The port comes from the command line because `EnvironmentFile=` would override an `Environment=` line. `CapEff: 0000000000000400` is bit 10, `CAP_NET_BIND_SERVICE`, and nothing else. Compare Lab 2.3, where `setcap` on the script did nothing.

### Step 6: Score it again, then put the app back on 8000.

```bash
systemd-analyze security shikumi-api.service --no-pager | tail -n 1
sudo rm /etc/systemd/system/shikumi-api.service.d/port80.conf
sudo systemctl daemon-reload && sudo systemctl restart shikumi-api
curl -s http://127.0.0.1:8000/healthz; echo
```

This lab restarts the service six times. The unit allows 20 starts in 60 seconds (`StartLimitBurst=`, `StartLimitIntervalSec=`), well above systemd's default of 5 in 10, and `setup.sh` resets the counter, so pasting the steps quickly is fine. If a restart still fails with `start of the service was attempted too often`, run `sudo systemctl reset-failed shikumi-api`, then `sudo systemctl start shikumi-api`.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 5.3
```

- `hardening.conf` is installed and the exposure score is below 5.0
- No `port80.conf` drop-in is left, and the service answers on port 8000
- `/etc/shikumi/shikumi-api.env` has no `SHIKUMI_CACHE` lines
- The service's effective capabilities are exactly `CAP_NET_BIND_SERVICE`

## Stretch challenge

Remove one line at a time from a copy of `hardening.conf` (try `SystemCallFilter=` and `RestrictAddressFamilies=`) and watch the score. Which single line is worth the most?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/05.3-sandboxing/cleanup.sh
```

Removes `port80.conf` and any `SHIKUMI_CACHE` lines, if left over. The hardening drop-in stays; later labs expect it. The script also removes `~/labs/5.3`.

## Coreutils used

`install`, `tail`, `head`, `cat`, `ls`, `printf`, `tee`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): the hardened unit passes systemd-analyze verify; offline exposure drops from 9.0 to 1.9.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
