# Lab 8.3: The OOM killer and memory limits

**Module M08 · Memory, page cache and disk I/O** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Run a growing process under a 100 MB cgroup limit, find the kernel's OOM record, and see how `oom_score_adj` steers the choice of victim.

## Before you start

- Lab 8.2 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/08.3-oom-killer/setup.sh
cd ~/labs/8.3
```

### Step 1: Look at overcommit and swap.

```bash
sysctl vm.overcommit_memory
grep -E 'CommitLimit|Committed_AS' /proc/meminfo
swapon --show; free -h
```

With overcommit mode 0 the kernel lets programs reserve more than it has, and settles the bill later with the OOM killer. Ubuntu cloud images have no swap.

### Step 2: Run alloc.py under a 100 MB limit.

```bash
sudo systemd-run --scope --uid="$USER" \
  -p MemoryMax=100M -p MemorySwapMax=0 --unit shikumi-oom \
  python3 ~/shikumi-linux-labs/app/alloc.py
echo "exit=$?"
```

It reaches about 90 MB and is killed. Exit status 137 is 128 + 9: SIGKILL, from the kernel.

### Step 3: Find the kernel's record.

```bash
sudo journalctl -k -g 'Memory cgroup out of memory' -n 2 --no-pager
sudo journalctl -k -g 'oom-kill:' -n 1 --no-pager
```

A cgroup OOM names the cgroup (`shikumi-oom.scope`), and kills inside it only. A system OOM says `Out of memory:` and may kill anything.

### Step 4: Steer the choice of victim.

```bash
python3 ~/shikumi-linux-labs/app/alloc.py --max-mb 50 & A=$!
sleep 6; cat /proc/$A/oom_score /proc/$A/oom_score_adj
echo 500 > /proc/$A/oom_score_adj; cat /proc/$A/oom_score
kill $A
systemctl show -p OOMScoreAdjust,MemoryMax shikumi-api
```

Anyone may raise their own score; lowering it needs privilege. Units set it with `OOMScoreAdjust=` and cap memory with `MemoryMax=`. `shikumi-api` shows `MemoryMax=268435456`, the 256 MB cap in its unit file: a leak in the service is killed inside its own cgroup, as in step 2, and never turns into a system OOM.

### Step 5: Check for a user-space OOM daemon.

```bash
systemctl status systemd-oomd --no-pager 2>&1 | head -n 3
```

Ubuntu cloud images do not run systemd-oomd. Desktops and Fedora do, and it acts on memory pressure before the kernel does.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Fedora runs zram swap and systemd-oomd by default. Run `zramctl` and `oomctl`, and check `journalctl -u systemd-oomd` to see whether oomd or the kernel acted. *(to verify)*

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 8.3
```

- The kernel log holds a `Memory cgroup out of memory` line
- No `shikumi-oom` unit is left running

## Stretch challenge

Run the same command with `-p MemoryHigh=80M -p MemoryMax=120M`. What changes before the kill? Watch `memory.events` in the scope's cgroup directory while it runs.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/08.3-oom-killer/cleanup.sh
```

Stops the `shikumi-oom` scope if it still exists, and removes `~/labs/8.3`.

## Coreutils used

`cat`, `sleep`, `head`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
