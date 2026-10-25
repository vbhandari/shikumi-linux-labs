# Lab 13.4: What Podman adds

**Module M13 · Containers from kernel primitives** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Run a rootless Podman container and find, from the host, the namespaces, cgroup, overlay mount, capabilities and seccomp filter it was given.

## Before you start

- Lab 13.3 done.
- Outbound HTTPS to Docker Hub.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/13.4-what-container-tools-add/setup.sh
cd ~/labs/13.4
```

### Step 1: Check what rootless mode needs.

```bash
podman --version
grep "^$USER:" /etc/subuid /etc/subgid
sudo aa-status | grep -E 'podman|crun|runc'
```

Your subordinate ID range gives the container's users real IDs on the host. Ubuntu's Podman profile grants `userns`, the same permission you gave `shikumi-unshare` in Lab 13.1.

### Step 2: Run a container as yourself.

```bash
podman run -d --name shikumi-alpine docker.io/library/alpine:3.24 sleep 600
podman ps
PID=$(podman inspect -f '{{.State.Pid}}' shikumi-alpine); echo "$PID"
```

### Step 3: Find its namespaces and ID mapping.

```bash
lsns -p "$PID"
readlink /proc/$PID/ns/net /proc/self/ns/net
cat /proc/$PID/uid_map
```

### Step 4: Find its cgroup.

```bash
cat /proc/$PID/cgroup
systemd-cgls --no-pager --user-unit 2>/dev/null |
  grep -B 3 '[s]leep 600' ||
  systemd-cgls --no-pager | grep -B 3 '[s]leep 600'
```

`[s]leep 600` still matches the container's `sleep 600`, but not grep's own command line, which reads `[s]leep`.

### Step 5: Find its root filesystem.

```bash
sudo findmnt -N "$PID" -o TARGET,SOURCE,FSTYPE /
sudo findmnt -N "$PID" -n -o OPTIONS / | tr ',' '\n'
podman image inspect alpine:3.24 -f '{{.RootFS.Layers}}'
```

`findmnt -N` runs the host's `findmnt` on the container's mount table (Alpine has no `findmnt`, so `nsenter -m findmnt` fails). The root is an overlay: read-only image layers below, a writable layer per container on top. The options get their own command, one per line: on one line they are so long that `findmnt` shortens the other columns, and `overlay` shows as `overla`.

### Step 6: Find its capabilities and seccomp filter.

```bash
grep -E 'CapEff|CapBnd|Seccomp' /proc/$PID/status
capsh --decode="$(awk '/CapEff/ {print $2}' /proc/$PID/status)"
```

The container's root has a reduced capability set, and `Seccomp: 2` means a syscall filter is active. Everything you built by hand in Lab 13.3, plus these, is what Podman does for you.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Same steps. Under SELinux the container process also carries a `container_t` label: `ps -eZ | grep 'sleep 600'`.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 13.4
```

- `shikumi-alpine` is running
- You have a `/etc/subuid` entry
- The container has its own network namespace, a seccomp filter (`Seccomp: 2`) and fewer capabilities than full root

## Stretch challenge

Run `podman run --rm --cap-drop=all alpine:3.24 grep Cap /proc/self/status` and compare with the default. Which capability does `ping` need?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/13.4-what-container-tools-add/cleanup.sh
```

Removes the container and the image. The script also removes `~/labs/13.4`.

## Coreutils used

`readlink`, `cat`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
