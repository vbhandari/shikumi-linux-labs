# Lab 2.2: Users, groups and an exact-command sudo rule

**Module M02 · Files, filesystems, users and permissions** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Create the `shikumi` service user and a `deploy` group, and give the group exactly one privileged command.

## Before you start

- Lab 2.1 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/90-shikumi-deploy`](files/90-shikumi-deploy)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/02.2-users-and-sudo/setup.sh
cd ~/labs/2.2
```

### Step 1: Look at who you are and how accounts are stored.

```bash
id
getent passwd "$USER" root
getent group sudo
sudo -V | head -n1
```

Ubuntu 26.04 uses sudo-rs, a Rust rewrite of sudo. Its password prompt reads `[sudo: authenticate] Password:`.

### Step 2: Create a system user for the service, with no login shell and no home.

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin --user-group shikumi
getent passwd shikumi
id shikumi
```

### Step 3: Create a deploy group and a person who belongs to it.

```bash
sudo groupadd deploy
sudo useradd --create-home --shell /bin/bash --groups deploy deployer
id deployer
```

### Step 4: Check the rule, then install it with safe ownership and mode.

```bash
sudo visudo -c -f 90-shikumi-deploy
sudo install -m 0440 -o root -g root 90-shikumi-deploy /etc/sudoers.d/
sudo visudo -c
```

Always validate before installing: a broken sudoers file can lock you out of `sudo`. Rules name exact commands; sudo-rs does not accept wildcards in arguments.

### Step 5: Confirm what deployer may run.

```bash
sudo -l -U deployer
sudo -l -U deployer /usr/bin/systemctl restart shikumi-api.service; echo "allowed: $?"
sudo -l -U deployer /usr/bin/systemctl stop shikumi-api.service; echo "allowed: $?"
```

> **Fedora / RHEL-family (alternate path, untested)**
>
> The admin group is `wheel`, not `sudo` (`getent group wheel`). Fedora uses classic sudo; the rule and `visudo` steps are the same.

> **Debian**
>
> Debian uses classic sudo (sudo.ws). If you set a root password during installation, your user may not be in `sudo` yet.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 2.2
```

- `shikumi` is a system user (UID below 1000) with shell `/usr/sbin/nologin`
- `deployer` is in group `deploy`
- `/etc/sudoers.d/90-shikumi-deploy` is mode 0440, owned by root, and passes `visudo -c`
- `sudo -l -U deployer` lists `/usr/bin/systemctl restart shikumi-api.service`, and `stop` is not allowed

## Stretch challenge

Give `deployer` a password (`sudo passwd deployer`), switch to it with `su - deployer`, and run the allowed command. Note the sudo-rs prompt, then try a different `systemctl` command and read the refusal.

## Cleanup

```bash
~/shikumi-linux-labs/labs/02.2-users-and-sudo/cleanup.sh
```

Removes the sudoers rule. It keeps the `shikumi` user, the `deploy` group and the `deployer` account, which Lab 2.3 and later labs use; `bin/shikumi-reset` removes them at the end of the course.

## Coreutils used

`id`, `head`, `install`, `stat`, `tr`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): user, group and sudo-rs rule steps and checks pass.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
