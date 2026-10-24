# Lab 15.1: Deploy the production-shaped stack

**Module M15 · Capstone: run it, break it, fix it** · about 30 min · [Lab index](../../README.md#lab-index)

**Goal:** From a clean snapshot, build the whole stack with one idempotent script, and verify every layer: hardened and confined instances, nginx with TLS, ufw, a persistent journal and the prune timer.

## Before you start

- A VM restored to the `clean` snapshot from Lab 0.1, with the repo up to date (`git -C ~/shikumi-linux-labs pull`).

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/15.1-deploy-the-stack/setup.sh
cd ~/labs/15.1
```

### Step 1: Read the deploy script.

```bash
less ~/shikumi-linux-labs/labs/15.1-deploy-the-stack/deploy.sh
```

Each block repeats a lab you have done: 2.2, 5.1, 5.3, 5.4, 6.2, 11.1, 12.1 and 12.2. Every command is safe to run twice. `deploy.sh` sits at the lab's root and runs from the repo; it is not copied to `~/labs`. It puts `ca.crt`, `server.crt` and `server.key` in `/etc/nginx/shikumi-tls/` and does not keep the CA key.

### Step 2: Run it.

```bash
sudo ~/shikumi-linux-labs/labs/15.1-deploy-the-stack/deploy.sh
```

### Step 3: Confirm SSH still works, then cancel the firewall undo.

```bash
sudo systemctl stop shikumi-ufw-revert.timer
```

Open a new SSH session from the host first. If it fails, wait 10 minutes: ufw turns itself off.

### Step 4: Check each layer yourself, then run the check.

```bash
systemctl list-units 'shikumi-*' --no-pager
ps -eZ | grep shikumi-api
systemd-analyze security shikumi-api@8001.service \
  --no-pager | tail -n 1
curl -s --cacert /etc/nginx/shikumi-tls/ca.crt \
  https://localhost/healthz; echo
sudo ufw status
~/shikumi-linux-labs/bin/shikumi-check lab 15.1
```

### Step 5: Run it again.

```bash
sudo ~/shikumi-linux-labs/labs/15.1-deploy-the-stack/deploy.sh
~/shikumi-linux-labs/bin/shikumi-check lab 15.1
```

Nothing breaks and nothing is duplicated: that is what idempotent means.

### Step 6: On the host, snapshot the working stack.

```bash
multipass stop shikumi && multipass snapshot shikumi --name stack && multipass start shikumi
# or, with Vagrant:
vagrant snapshot save ubuntu stack
```

Lab 15.2 breaks this stack seven times. `break.sh --undo` repairs it; if a drill goes badly wrong, `multipass restore shikumi.stack` (or `vagrant snapshot restore ubuntu stack`) brings it back.

> **Fedora / RHEL-family (alternate path, untested)**
>
> The Fedora equivalent keeps SELinux enforcing and uses firewalld: install the nginx config to `conf.d`, `setsebool -P httpd_can_network_connect 1`, and open `http` and `https` with `firewall-cmd --permanent`. `deploy.sh` covers Ubuntu only. *(to verify)*

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 15.1
```

- `shikumi-api@8001` and `@8002` are enabled, active and confined by the AppArmor profile in enforce mode, with exposure below 5.0
- nginx serves `https://localhost/healthz` over HTTP/2 with the lab CA, and redirects HTTP with 301
- ufw is active and allows OpenSSH, 80/tcp and 443/tcp; its undo timer is not pending
- The journal is persistent and `shikumi-prune.timer` is active

## Stretch challenge

Add a `--check` flag to `deploy.sh` that reports what it *would* change without changing anything. Which steps are hard to predict, and why?

## Cleanup

```bash
~/shikumi-linux-labs/labs/15.1-deploy-the-stack/cleanup.sh
```

Nothing to undo: Lab 15.2 breaks this stack on purpose. To remove everything the course installed, run `~/shikumi-linux-labs/bin/shikumi-reset`, or restore the `clean` snapshot. Keep the `stack` snapshot for Lab 15.2.

## Coreutils used

`install`, `ln`, `rm`, `mktemp`, `tail`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
