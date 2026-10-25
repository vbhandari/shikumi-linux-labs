# Lab 2.3: A shared release directory, and why port 80 is refused

**Module M02 · Files, filesystems, users and permissions** · about 25 min · [Lab index](../../README.md#lab-index)

**Goal:** Build `/srv/shikumi` so the `deploy` group can write and the `shikumi` user can only read, then see that a normal user cannot bind port 80 and that capabilities on a script change nothing.

## Before you start

- Lab 2.2 done: you need `shikumi`, `deploy` and `deployer`, which its cleanup keeps. If one is missing, re-run Lab 2.2 steps 2 and 3.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/02.3-permissions-and-capabilities/setup.sh
cd ~/labs/2.3
```

### Step 1: See umask at work.

```bash
umask
touch file1; mkdir dir1
ls -ld file1 dir1
stat -c '%a %U:%G %n' file1 dir1
```

### Step 2: Create the release directory: group deploy, setgid, no access for others.

```bash
sudo install -d -m 2770 -o root -g deploy /srv/shikumi
ls -ld /srv/shikumi
```

The `s` in the group position is setgid: new files inherit group `deploy`.

### Step 3: Let shikumi read, now and for files created later.

```bash
sudo setfacl -m u:shikumi:rx -m d:u:shikumi:rx \
  -m d:g:deploy:rwx /srv/shikumi
getfacl /srv/shikumi
```

### Step 4: Test as each user.

```bash
sudo -u deployer bash -c 'echo v1 > /srv/shikumi/release.txt'
sudo ls -l /srv/shikumi
sudo -u shikumi cat /srv/shikumi/release.txt
sudo -u shikumi touch /srv/shikumi/nope
```

The `+` after the mode of `release.txt` means it has an ACL, inherited from the default ACL. Ubuntu 26.04's `ls` (uutils) prints it with no space before the link count, as in `-rw-rw----+1`.

### Step 5: Compare with the sticky bit on /tmp.

```bash
ls -ld /tmp
```

The `t` means anyone may create files, but only the owner may delete them.

### Step 6: Try to bind port 80 as yourself.

```bash
grep Cap /proc/self/status
sysctl net.ipv4.ip_unprivileged_port_start
python3 ~/shikumi-linux-labs/app/shikumi_api.py --port 80
```

It stops with `PermissionError: [Errno 13] Permission denied`. Ports below 1024 need `CAP_NET_BIND_SERVICE`.

### Step 7: Capabilities attach to binaries, not scripts.

```bash
cp ~/shikumi-linux-labs/app/shikumi_api.py api-copy.py
sudo setcap cap_net_bind_service=+ep api-copy.py
getcap api-copy.py
./api-copy.py --port 80
```

Still refused: the kernel runs `/usr/bin/python3`, and the script's file capability is ignored. Lab 5.3 grants the capability to the service with systemd instead.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Same steps. Files under `/srv` also carry an SELinux label (`ls -Z /srv/shikumi`); Lab 6.1's alternate path uses it.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 2.3
```

- `/srv/shikumi` is mode 2770, owner root, group deploy, with ACLs for `shikumi` (current and default)
- deployer can create files there; shikumi can read but not create
- Binding port 80 as a normal user fails with `Errno 13`

## Stretch challenge

Find every setuid binary on the system with `find / -xdev -perm -4000 -type f 2>/dev/null` and look up why `passwd` needs it.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/02.3-permissions-and-capabilities/cleanup.sh
```

Removes `/srv/shikumi`, the script copy and `~/labs/2.3`. Users and groups stay.

## Coreutils used

`touch`, `mkdir`, `ls`, `stat`, `install`, `cp` (GNU), `cat`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): install -d, ACL and capability steps and checks pass.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
