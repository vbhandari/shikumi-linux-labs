# Lab 13.1: Namespaces, and who may create them

**Module M13 · Containers from kernel primitives** · about 30 min · [Lab index](../../README.md#lab-index)

**Goal:** Give a shell its own hostname and PID space, enter it from outside, see Ubuntu refuse an unprivileged user namespace, and grant that permission to exactly one lab binary.

## Before you start

- Lab 12.2 done.
- Take a VM snapshot first.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/13.1-namespaces-and-userns/setup.sh
cd ~/labs/13.1
```

### Step 1: See the namespaces your shell is in.

```bash
ls -l /proc/self/ns
lsns -t uts,pid,net | head
```

### Step 2: Start a shell with its own hostname and PID namespace.

```bash
sudo unshare --uts --pid --fork --mount-proc bash
hostname shikumi-ns; hostname
ps -ef
echo "my PID here: $$"
```

Inside, `ps` shows only this shell and its children, and the shell is PID 1. The VM's hostname is unchanged. Leave this shell open.

### Step 3: In a second terminal, find it and enter it.

```bash
PID=$(pgrep -P "$(pgrep -n -x unshare)")
echo "the same shell, seen from the host: PID $PID"
sudo readlink /proc/$PID/ns/uts /proc/self/ns/uts
sudo nsenter -t "$PID" -a hostname
sudo nsenter -t "$PID" -a ps -ef
```

Type `exit` in the first terminal when you are done.

### Step 4: Try a user namespace as yourself.

```bash
sysctl kernel.apparmor_restrict_unprivileged_userns
unshare -r id; echo "exit=$?"
sudo journalctl -k -g userns -n 3 --no-pager
```

With the restriction on, an unprivileged process may create a user namespace only if its AppArmor profile grants `userns`. `unshare` has no such profile, so it gets no privileges inside and fails with `write failed /proc/self/uid_map: Operation not permitted`.

### Step 5: Grant the permission to one lab-only binary.

```bash
cat ~/shikumi-linux-labs/config/apparmor/shikumi-unshare
sudo install -m 0755 /usr/bin/unshare /usr/local/bin/shikumi-unshare
sudo install -m 0644 ~/shikumi-linux-labs/config/apparmor/shikumi-unshare /etc/apparmor.d/
sudo apparmor_parser -r /etc/apparmor.d/shikumi-unshare
sudo aa-status | grep shikumi-unshare
```

The profile is `unconfined` apart from adding `userns`: the same shape Ubuntu ships for Podman, runc and rootlesskit.

### Step 6: Compare the two binaries.

```bash
shikumi-unshare -r id
shikumi-unshare -r cat /proc/self/uid_map
unshare -r id; echo "exit=$?"
sysctl kernel.apparmor_restrict_unprivileged_userns
```

Only the profiled path gained the permission, and the system-wide setting is still 1. Never turn the sysctl off to make a tool work.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Fedora has no such restriction: `unshare -r id` works as a normal user. Skip steps 5 and 6.

> **Debian**
>
> Same as Fedora: no restriction.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 13.1
```

- `kernel.apparmor_restrict_unprivileged_userns` is still 1
- `/usr/local/bin/shikumi-unshare` exists and its profile is loaded
- `shikumi-unshare -r id -u` prints 0, while `unshare -r` still fails

## Stretch challenge

Find every profile on the VM that grants `userns`: `sudo grep -l 'userns,' /etc/apparmor.d/*`. Pick one and find out which program it is for.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/13.1-namespaces-and-userns/cleanup.sh
```

Unloads the profile, removes both files, and fails loudly if the userns sysctl is no longer 1. Safe to run before Lab 13.3: its setup reinstalls `shikumi-unshare`.

## Coreutils used

`ls`, `head`, `readlink`, `install`, `cat`, `id`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
