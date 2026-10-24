# Lab 8.4: The cost of fsync

**Module M08 · Memory, page cache and disk I/O** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Run two short `fio` jobs, buffered and with `fsync` after every write, and read the difference in `iostat`.

## Before you start

- Lab 8.3 done.
- 300 MB free disk in `$HOME`.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/08.4-disk-io/setup.sh
cd ~/labs/8.4
```

### Step 1: Look at the disks.

```bash
lsblk
findmnt /
```

In a VM the disk is virtual (`vda` or `sda`), and its speed depends on the host.

### Step 2: Start iostat in a second terminal.

```bash
iostat -xz 1
```

`w/s` is writes per second, `w_await` the average write latency in ms, `%util` how busy the device is.

### Step 3: Run a buffered random-write job for 30 seconds.

```bash
fio --name=buffered --filename=fio.dat --size=256M --rw=randwrite --bs=4k \
    --ioengine=psync --runtime=30 --time_based --group_reporting | tee buffered.txt
```

### Step 4: Run it again with fsync after every write.

```bash
fio --name=fsync --filename=fio.dat --size=256M --rw=randwrite --bs=4k \
    --ioengine=psync --runtime=30 --time_based --group_reporting --fsync=1 | tee fsync.txt
```

### Step 5: Compare.

```bash
grep -E 'write: IOPS|clat \(' buffered.txt fsync.txt
```

Buffered writes land in the page cache, so fio measures memory. With `--fsync=1` every write waits for the disk. A database that promises durability pays this cost on every commit.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 8.4
```

- `buffered.txt` and `fsync.txt` both hold fio results
- The fsync job's IOPS are lower than the buffered job's

## Stretch challenge

Repeat the fsync job with `--bs=64k`. Does throughput (MB/s) or IOPS change more, and why?

## Cleanup

```bash
~/shikumi-linux-labs/labs/08.4-disk-io/cleanup.sh
```

Deletes `fio.dat` and the results.

## Coreutils used

`tee`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
