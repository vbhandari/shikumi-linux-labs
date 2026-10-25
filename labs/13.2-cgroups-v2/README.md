# Lab 13.2: Throttle a busy loop with cgroups v2

**Module M13 · Containers from kernel primitives** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Hold a busy loop to 20 % of one CPU, first with `systemd-run`, then by writing the cgroup files yourself, and confirm with the throttling counters.

## Before you start

- Lab 13.1 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/13.2-cgroups-v2/setup.sh
cd ~/labs/13.2
```

### Step 1: Look at the hierarchy.

```bash
cat /proc/self/cgroup
systemd-cgls --no-pager | head -n 25
cat /sys/fs/cgroup/cgroup.subtree_control
```

### Step 2: Let systemd set the limit.

```bash
sudo systemd-run --unit shikumi-burn -p CPUQuota=20% python3 -c 'while True: pass'
sleep 5; top -b -n 1 | grep -m1 python3
cat /sys/fs/cgroup/system.slice/shikumi-burn.service/cpu.max
grep throttled /sys/fs/cgroup/system.slice/shikumi-burn.service/cpu.stat
sudo systemctl stop shikumi-burn
```

`CPUQuota=20%` becomes `cpu.max` "20000 100000": 20 ms of CPU time in every 100 ms period. `nr_throttled` counts the periods in which the group hit its quota.

### Step 3: Do the same by hand.

```bash
sudo mkdir /sys/fs/cgroup/shikumi
ls /sys/fs/cgroup/shikumi | head
echo "20000 100000" | sudo tee /sys/fs/cgroup/shikumi/cpu.max
python3 -c 'while True: pass' & B=$!
echo $B | sudo tee /sys/fs/cgroup/shikumi/cgroup.procs
cat /proc/$B/cgroup
sleep 5; top -b -n 1 -p $B | tail -n 2
cat /sys/fs/cgroup/shikumi/cpu.stat
kill $B
```

If `cpu.max` is missing, the root does not delegate the CPU controller yet: `echo +cpu | sudo tee /sys/fs/cgroup/cgroup.subtree_control`.

### Step 4: Watch all groups at once.

```bash
systemd-cgtop -b -n 2 --depth 2 | head -n 20
```

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 13.2
```

- `/sys/fs/cgroup/shikumi` exists with `cpu.max` set to `20000 100000`
- Its `cpu.stat` shows `nr_throttled` above 0
- `shikumi-burn` is no longer running

## Stretch challenge

Add `memory.max` 50M to the `shikumi` group and move `python3 ~/shikumi-linux-labs/app/alloc.py` into it. Read `memory.events` after the kill and compare with Lab 8.3.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/13.2-cgroups-v2/cleanup.sh
```

Kills anything left in the `shikumi` group, removes it, and stops `shikumi-burn`. The script also removes `~/labs/13.2`.

## Coreutils used

`cat`, `ls`, `head`, `tail`, `tee`, `sleep`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
