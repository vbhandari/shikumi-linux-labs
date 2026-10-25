# Lab 8.1: RSS, VSZ and a memory-mapped file

**Module M08 · Memory, page cache and disk I/O** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Read a process's memory from `/proc`, then map a 500 MB file and watch RSS rise while VSZ stays flat.

## Before you start

- Lab 7.2 done.
- 1 GB free disk in `$HOME`.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/08.1-virtual-memory/setup.sh
cd ~/labs/8.1
```

### Step 1: Read the machine's memory.

```bash
free -h
grep -E 'MemTotal|MemFree|MemAvailable|^Cached' /proc/meminfo
```

`available` is what new work can use, including page cache the kernel can drop. `free` is only memory nobody uses, and is usually small on a healthy machine.

### Step 2: Read the service's memory.

```bash
PID=$(systemctl show -p MainPID --value shikumi-api)
ps -o pid,vsz,rss,cmd -p "$PID"
sudo grep -E 'VmSize|VmRSS|RssAnon|RssFile' /proc/"$PID"/status
sudo cat /proc/"$PID"/smaps_rollup
```

VSZ counts every mapping, used or not. RSS counts pages in RAM. PSS shares the cost of shared pages between the processes that map them.

### Step 3: Map a 500 MB file and touch it page by page.

```bash
python3 ~/shikumi-linux-labs/app/mmapdemo.py ~/labs/8.1/big.bin --mb 500
```

In a second terminal, run the `grep` command it prints under `watch -n 1`. Press Enter in the first terminal. `VmRSS` (and `RssFile`) grows by 50 MB a second; `VmSize` does not change, because the whole file was mapped at the start.

### Step 4: Compare with anonymous memory.

```bash
python3 ~/shikumi-linux-labs/app/alloc.py --max-mb 300 & A=$!
sleep 8; grep -E 'VmRSS|RssAnon|RssFile' /proc/$A/status; free -h
kill $A
```

`bytearray` memory is anonymous: no file backs it, so the kernel can only reclaim it by swapping, and a cloud VM usually has no swap.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 8.1
```

- `~/labs/8.1/big.bin` exists (500 MB)
- A batch run of `mmapdemo.py` raises VmRSS by at least 50 MB with VmSize unchanged

## Stretch challenge

Run two copies of `mmapdemo.py` on the same file and compare their `Pss` in `smaps_rollup`. Why does each copy's PSS show about half the file?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/08.1-virtual-memory/cleanup.sh
```

Deletes `big.bin` and stops any `mmapdemo.py` or `alloc.py`.

## Coreutils used

`ps` (procps), `cat`, `sleep`, `mktemp`, `rm`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): steps and checks pass.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
