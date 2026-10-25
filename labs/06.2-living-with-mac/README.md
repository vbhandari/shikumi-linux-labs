# Lab 6.2: Complain, refine, enforce: confine both instances

**Module M06 · Mandatory access control: AppArmor (core) · SELinux (alternate)** · about 30 min · [Lab index](../../README.md#lab-index)

**Goal:** Turn on the app's cache, watch the profile block it, learn the missing rule in complain mode, and enforce again with both `shikumi-api@` instances confined.

## Before you start

- Lab 6.1 done (profile loaded in enforce mode).
- Paste one block at a time, as in Lab 0.1 (*Pasting*).

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/cache.conf`](files/cache.conf)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/06.2-living-with-mac/setup.sh
cd ~/labs/6.2
```

### Step 1: Turn the cache on for the template instances.

```bash
sudo install -D -m 0644 cache.conf /etc/systemd/system/shikumi-api@.service.d/cache.conf
sudo systemctl daemon-reload
sudo systemctl restart shikumi-api@8001 shikumi-api@8002
curl -s 'http://127.0.0.1:8001/data?name=hello.txt'; echo
sudo journalctl -k -g 'apparmor="DENIED"' -n 2 --no-pager
```

The read succeeds, the cache write is denied, and the request fails with 500.

### Step 2: Switch the profile to complain mode and repeat.

```bash
sudo aa-complain /opt/shikumi/bin/shikumi-api
```

Wait for `Setting /opt/shikumi/bin/shikumi-api to complain mode.`, then repeat the request:

```bash
curl -s 'http://127.0.0.1:8001/data?name=hello.txt'; echo
sudo journalctl -k -g 'apparmor="ALLOWED"' -n 2 --no-pager
```

In complain mode the profile logs what it would have denied, and allows it.

### Step 3: Let aa-logprof propose the rule, from the cache events only.

```bash
g='shikumi-api" name="/var/cache/shikumi/'
sudo journalctl -k -b --no-pager -g "$g" > cache.log
wc -l cache.log
sudo aa-logprof -f cache.log
```

Plain `sudo aa-logprof` reads every AppArmor event on the system, including old ones from 6.1 and from other profiles such as `systemd-detect-virt`. `-f cache.log` limits it to the cache events. Choose **(G)lob** until the path reads `/var/cache/shikumi/*`, then **(A)llow**, and **(S)ave**.

If aa-logprof still offers anything that is not under `/var/cache/shikumi`, or for a profile other than `/opt/shikumi/bin/shikumi-api`, choose **(I)gnore**. Never save changes to another profile, and don't accept `/srv/shikumi-data`: that would undo Lab 6.1.

Instead of `aa-logprof`, you can install the reference rule, which keeps site-specific rules in `local/`:

```bash
sudo install -m 0644 ~/shikumi-linux-labs/config/apparmor/local/opt.shikumi.bin.shikumi-api /etc/apparmor.d/local/
sudo apparmor_parser -r /etc/apparmor.d/opt.shikumi.bin.shikumi-api
```

This works only if the profile ends with `include if exists <local/opt.shikumi.bin.shikumi-api>`, as the reference profile does.

### Step 4: Enforce again and confirm both instances are confined.

```bash
sudo aa-enforce /opt/shikumi/bin/shikumi-api
sudo systemctl restart shikumi-api@8001 shikumi-api@8002
curl -s 'http://127.0.0.1:8001/data?name=hello.txt'; echo
curl -s 'http://127.0.0.1:8002/data?name=hello.txt'; echo
ps -eZ | grep shikumi-api
ls -l /var/cache/shikumi
```

Both instances run the profiled path, so both are confined without any change to the unit. `AppArmorProfile=` in a unit is the alternative when a service's path does not match a profile.

### Step 5: Know how to remove a profile safely (read only; do not run now).

```bash
sudo aa-disable /opt/shikumi/bin/shikumi-api              # unload and disable at boot
sudo apparmor_parser -R /etc/apparmor.d/opt.shikumi.bin.shikumi-api   # unload only
```

Never "fix" a denial by turning AppArmor off. Read the denial, then change the policy.

> **Fedora / RHEL-family (alternate path, untested)**
>
> SELinux uses booleans and port labels where AppArmor uses path rules:
>
> ```bash
> getsebool httpd_can_network_connect
> sudo setsebool -P httpd_can_network_connect 1     # Lab 12.1 needs this on Fedora
> sudo semanage port -l | grep http_port_t
> sudo ausearch -m avc -ts recent | audit2why
> ```

> **Debian**
>
> Same as Ubuntu.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 6.2
```

- The profile is back in enforce mode
- `shikumi-api@8001` and `@8002` both run confined by it
- `/data` returns 200 on both ports with the cache on, and `/var/cache/shikumi/hello.txt.cache` exists

## Stretch challenge

Point the cache at `/var/lib/shikumi/cache` instead (`SHIKUMI_CACHE_DIR=` in `cache.conf`). Does the profile need a new rule? Why not?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/06.2-living-with-mac/cleanup.sh
```

Removes the `cache.conf` drop-in, restarts the instances and removes `~/labs/6.2`. The profile and its local rule stay; Lab 15.1 installs them again anyway.

## Coreutils used

`install`, `ls`, `cat`, `tr`, `wc`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
