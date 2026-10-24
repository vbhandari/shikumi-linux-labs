# Lab 4.1: Install nginx and find everything it brought

**Module M04 · Packages: apt first, dnf alongside** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Install nginx with apt, see that Ubuntu starts it on port 80 straight away, find its unit, config and logs from the package database, and then disable it.

## Before you start

- Lab 3.3 done.
- nginx not installed yet. The VM setup (`vm/provision.sh`, cloud-init) deliberately leaves it out; `setup.sh` warns if it is already there.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/04.1-installing-software/setup.sh
cd ~/labs/4.1
```

### Step 1: Ask apt about nginx before installing.

```bash
apt policy nginx
apt show nginx 2>/dev/null | head -n 15
grep -h '^Signed-By\|^URIs' /etc/apt/sources.list.d/*.sources
```

### Step 2: Install it.

```bash
sudo apt install -y nginx
systemctl status nginx --no-pager | head -n 5
ss -tln | grep ':80 '
curl -sI http://127.0.0.1/ | head -n 1
```

On Ubuntu and Debian, a package's service starts as soon as it is installed. nginx is already listening on port 80.

### Step 3: Find what the package installed.

```bash
dpkg -S nginx.service
dpkg -L nginx-common | grep -E '\.service$|nginx.conf$|logrotate'
dpkg -L nginx | grep bin/
ls -l /var/log/nginx
```

nginx is split in two packages. `nginx` holds only the binary, `/usr/sbin/nginx`. `nginx-common` holds everything around it: `nginx.service`, `/etc/nginx`, the logrotate rule and `/var/log/nginx`. Removing `nginx` leaves the configuration; `apt purge nginx-common` removes it too. `nginx-core` is only a transitional package that pulls in `nginx`.

### Step 4: Hold a package, and look at automatic security updates.

```bash
sudo apt-mark hold nginx; apt-mark showhold
sudo apt-mark unhold nginx
cat /etc/apt/apt.conf.d/20auto-upgrades
systemctl list-timers 'apt-*' --no-pager
```

### Step 5: Disable nginx and free port 80.

```bash
sudo systemctl disable --now nginx
ss -tln | grep ':80 ' || echo "port 80 is free"
```

Lab 5.3 needs port 80 for the app. M12 enables nginx again.

> **Fedora / RHEL-family (alternate path, untested)**
>
> ```bash
> sudo dnf install -y nginx
> rpm -qf /usr/lib/systemd/system/nginx.service
> rpm -ql nginx | grep -E 'service|nginx.conf'
> dnf history; sudo dnf history undo last
> ```
> Services do **not** start on install on Fedora: run `sudo systemctl enable --now nginx` yourself. Automatic updates come from `dnf-automatic`.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 4.1
```

- nginx is installed
- `nginx.service` is disabled and inactive
- Nothing listens on port 80
- nginx is not held

## Stretch challenge

Find which package owns `/usr/bin/ss` and list its other files. Then find a file on the system that no package owns: `dpkg -S /usr/local/bin` is a hint.

## Cleanup

```bash
~/shikumi-linux-labs/labs/04.1-installing-software/cleanup.sh
```

Nothing to undo: nginx stays installed and disabled for M12. The script only makes sure nginx is not held.

## Coreutils used

`head`, `ls`, `cat`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
