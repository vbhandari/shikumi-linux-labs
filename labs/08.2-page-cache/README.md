# Lab 8.2: Page cache and dirty pages

**Module M08 · Memory, page cache and disk I/O** · about 25 min · [Lab index](../../README.md#lab-index)

**Goal:** Time a cold read against a warm one, watch unsynced writes pile up as dirty pages and drain, and change the writeback threshold for this boot only.

## Before you start

- Lab 8.1 done.
- 600 MB free disk in `$HOME`.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/mkdata.py`](files/mkdata.py)
- [`files/writer.py`](files/writer.py)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/08.2-page-cache/setup.sh
cd ~/labs/8.2
```

### Step 1: Create a test file and see what is cached.

```bash
python3 mkdata.py data.bin --mb 300
fincore data.bin
vmtouch data.bin
```

### Step 2: Time a cold read, then a warm one.

```bash
sync; echo 3 | sudo tee /proc/sys/vm/drop_caches
fincore data.bin
time cat data.bin > /dev/null
fincore data.bin
time cat data.bin > /dev/null
```

`drop_caches` is for experiments only: it throws away useful cache on a real server.

### Step 3: Watch dirty pages while writing without fsync, then with it.

```bash
watch -n 1 "grep -E '^(Dirty|Writeback):' /proc/meminfo"
```

Run that in a second terminal. Then, in the first:

```bash
python3 writer.py out.bin --mb 200
python3 writer.py out.bin --mb 200 --fsync
```

Without fsync the write "finishes" quickly and `Dirty` rises, then drains over the next seconds. With fsync the program waits until the data is on disk.

### Step 4: Lower the background writeback threshold for this boot only, and compare.

```bash
sysctl vm.dirty_background_ratio vm.dirty_ratio
sysctl -n vm.dirty_background_ratio > dirty_background_ratio.orig
sudo sysctl vm.dirty_background_ratio=1
python3 writer.py out.bin --mb 200
sudo sysctl vm.dirty_background_ratio="$(cat dirty_background_ratio.orig)"
```

Writeback now starts sooner, so `Dirty` stays lower. `sysctl` changes are lost at reboot; the course never writes them to `/etc/sysctl.d`.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 8.2
```

- `data.bin` exists
- `vm.dirty_background_ratio` is back to the value saved in `dirty_background_ratio.orig`

## Stretch challenge

Find which files of the running service are in the page cache: `sudo fincore /usr/bin/python3.*` and the files under `/usr/lib/python3*/`.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/08.2-page-cache/cleanup.sh
```

Restores `vm.dirty_background_ratio` if a saved value exists, and deletes the test files.

## Coreutils used

`cat`, `sync`, `tee`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
