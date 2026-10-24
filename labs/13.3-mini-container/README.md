# Lab 13.3: Build a mini container by hand

**Module M13 · Containers from kernel primitives** · about 35 min · [Lab index](../../README.md#lab-index)

**Goal:** Turn an Alpine root filesystem into a container with nothing but `unshare`, `mount` and `pivot_root`, then limit it with a cgroup and give it a network link.

## Before you start

- Labs 13.1 and 13.2 done. The stretch uses `shikumi-unshare` from Lab 13.1; `setup.sh` reinstalls it if a cleanup removed it.
- Outbound HTTPS to dl-cdn.alpinelinux.org.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/mini-container.sh`](files/mini-container.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/13.3-mini-container/setup.sh
cd ~/labs/13.3
```

### Step 1: Look at the root filesystem setup.sh downloaded.

```bash
ls rootfs
cat rootfs/etc/os-release | head -n 2
```

setup.sh fetched the Alpine minirootfs for `$(uname -m)` and checked its SHA-256 before unpacking it.

### Step 2: Create new namespaces.

```bash
sudo unshare --mount --uts --ipc --net --pid --fork bash
```

Run the following steps inside this root shell. `unshare` makes the new mount namespace's mounts private, so nothing you mount leaks to the host.

### Step 3: Make the new root a mount point, and switch to it.

```bash
cd ~/labs/13.3          # if HOME changed under sudo, cd to the full path instead
mount --bind rootfs rootfs
cd rootfs
mkdir -p .old
pivot_root . .old
```

`pivot_root` needs the new root to be a mount point, hence the bind mount onto itself. It moves the old root to `/.old`.

### Step 4: Mount /proc and drop the old root.

```bash
hash -r
mount -t proc proc /proc
umount -l /.old && rmdir /.old
hostname shikumi-ctr
exec /bin/sh
```

`hash -r` makes bash forget the paths it remembered for commands such as `mount`: they pointed into the old root. From here on, every command is Alpine's BusyBox.

### Step 5: Look around from inside.

```bash
cat /etc/alpine-release
ps
hostname
ip link 2>/dev/null || ls /sys/class/net
```

PID 1 is your shell, the host's processes are invisible, and the only network interface is a loopback that is down. Leave this shell open.

### Step 6: From a second terminal, put the container in a cgroup.

```bash
PID=$(pgrep -P "$(pgrep -n -x unshare)")
sudo mkdir -p /sys/fs/cgroup/shikumi-ctr
echo "50000 100000" | sudo tee /sys/fs/cgroup/shikumi-ctr/cpu.max
echo 64M | sudo tee /sys/fs/cgroup/shikumi-ctr/memory.max
echo "$PID" | sudo tee /sys/fs/cgroup/shikumi-ctr/cgroup.procs
cat /proc/$PID/cgroup
```

### Step 7: Give it a network link.

```bash
sudo ip link add veth-ctr type veth peer name veth-ctr-in
sudo ip link set veth-ctr-in netns "$PID"
sudo ip addr add 10.200.2.1/24 dev veth-ctr
sudo ip link set veth-ctr up
sudo nsenter -t "$PID" -n ip addr add 10.200.2.2/24 dev veth-ctr-in
sudo nsenter -t "$PID" -n ip link set veth-ctr-in up
sudo nsenter -t "$PID" -n ip link set lo up
ping -c 2 10.200.2.2
```

`nsenter -n` enters only the network namespace, so it runs the host's `ip` binary. Type `exit` in the container shell when you are done; the namespaces go away with their last process.

### Step 8: Compare with unshare --root, and use the script.

```bash
sudo unshare --mount --pid --fork \
  --root ~/labs/13.3/rootfs --mount-proc \
  /bin/sh -c 'ps; ls /'
sudo ./mini-container.sh rootfs \
  /bin/sh -c 'echo "PID $$ on $(hostname)"; ps'
```

`--root` uses `chroot`: simpler, but the old root is still mounted underneath, and a process with enough privilege can climb out. `pivot_root` detaches it.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 13.3
```

- `rootfs/etc/alpine-release` exists
- `sudo ./mini-container.sh rootfs` gives a shell that is PID 1 on host name `shikumi-ctr`
- The `shikumi-ctr` cgroup exists with `cpu.max` 50000 100000

## Stretch challenge

Run the same container without sudo: `./mini-container.sh --rootless rootfs`. Inside, `id` says root; on the host, `ps -o user,pid,cmd -p PID` shows your own user. Which steps would have failed with plain `unshare`?

## Cleanup

```bash
~/shikumi-linux-labs/labs/13.3-mini-container/cleanup.sh
```

Removes the veth, the `shikumi-ctr` cgroup (after killing anything in it), the root filesystem, and `shikumi-unshare` with its profile. Running the Lab 13.1 cleanup too is harmless.

## Coreutils used

`ls`, `cat`, `head`, `readlink`, `mkdir`, `rmdir`, `tee`, `sha256sum`, `cut`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. On a Debian 13 host, setup, the root mini container (PID 1, host name shikumi-ctr) and the rootless variant work; the cgroup step was not run.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
