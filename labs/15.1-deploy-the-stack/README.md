# Lab 15.1: Deploy the production-shaped stack

**Module M15 · Capstone: run it, break it, fix it** · about 30 min · [Lab index](../../README.md#lab-index)

**Goal:** From a clean snapshot, build the whole stack with one idempotent script, and verify every layer: hardened and confined instances, nginx with TLS, ufw, a persistent journal and the prune timer.

## Before you start

- A VM restored to the `clean` snapshot from Lab 0.1, with the repo up to date on `main`: `git -C ~/shikumi-linux-labs checkout main && git -C ~/shikumi-linux-labs pull --ff-only` (the `checkout` matters if `git status` says `HEAD detached`). If you pinned the repo to a release tag on purpose, as the course's VM tests do, this moves you off it; skip the command, or go back afterwards with `git -C ~/shikumi-linux-labs checkout TAG`.

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

Each block repeats a lab you have done: 2.2, 5.1, 5.3, 5.4, 6.2, 11.1, 12.1 and 12.2. Every command is safe to run twice. `deploy.sh` sits at the lab's root and runs from the repo; it is not copied to `~/labs`. It puts `ca.crt`, `server.crt` and `server.key` in `/etc/nginx/shikumi-tls/` and deletes the CA key, which nothing on the stack needs. Its last step, *Exposure*, stops with an error unless nginx answers 404 for `/alloc` and both instances have a `MemoryMax=`: the site proxies only `/healthz`, and the units cap memory at 256 MB.

**On a public cloud VM**, the *Firewall* step opens 80 and 443 in ufw to the whole internet. Keep the provider's firewall from Lab 0.1 in front (inbound SSH from your own IP only), and allow 80 and 443 there only from your own IP, if at all.

### Step 2: Run it.

```bash
sudo ~/shikumi-linux-labs/labs/15.1-deploy-the-stack/deploy.sh
```

### Step 3: Confirm SSH still works, then cancel the firewall undo.

```bash
systemctl is-active --quiet shikumi-ufw-revert.timer &&
  sudo systemctl stop shikumi-ufw-revert.timer
```

Open a new SSH session from the host first. If it fails, wait 10 minutes: ufw turns itself off. `deploy.sh` arms the undo only when ufw was not active yet, so if ufw was already on (after Lab 11.1, or on a second run) there is no timer and this step does nothing.

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

Lab 15.2 breaks this stack seven times. `break.sh --undo` repairs it; if a drill goes badly wrong, `multipass restore shikumi.stack` (or `vagrant snapshot restore ubuntu stack`) brings it back. On a cloud VM, take the `stack` snapshot in the provider's console, and restore it from there.

> **Fedora / RHEL-family (alternate path, untested)**
>
> The Fedora equivalent keeps SELinux enforcing and uses firewalld: install the nginx config to `conf.d`, `setsebool -P httpd_can_network_connect 1`, and open `http` and `https` with `firewall-cmd --permanent`. `deploy.sh` covers Ubuntu only. *(to verify)*

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 15.1
```

- `shikumi-api@8001` and `@8002` are enabled, active and confined by the AppArmor profile in enforce mode, with exposure below 5.0
- nginx serves `https://localhost/healthz` over HTTP/2 with the lab CA, redirects HTTP with 301, and answers 404 for `/alloc`
- Both instances have `MemoryMax=256M` and `TasksMax=64`
- ufw is active and allows OpenSSH, 80/tcp and 443/tcp; its undo timer is not pending
- The journal is persistent and `shikumi-prune.timer` is active

## Stretch challenge

Add a `--check` flag to `deploy.sh` that reports what it *would* change without changing anything. Which steps are hard to predict, and why?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/15.1-deploy-the-stack/cleanup.sh
```

Removes `~/labs/15.1` and nothing else: Lab 15.2 breaks this stack on purpose. To remove everything the course installed, run `~/shikumi-linux-labs/bin/shikumi-reset`, or restore the `clean` snapshot. Keep the `stack` snapshot for Lab 15.2.

## Coreutils used

`install`, `ln`, `rm`, `mktemp`, `tail`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
