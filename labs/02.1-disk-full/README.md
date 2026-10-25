# Lab 2.1: Disk full, but nothing is big

**Module M02 · Files, filesystems, users and permissions** · about 25 min · [Lab index](../../README.md#lab-index)

**Goal:** Fill a small filesystem from a process that keeps a deleted log file open, find the space with `lsof -a +L1`, recover it, and then run out of inodes instead of bytes.

## Before you start

- Lab 0.1 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/holdlog.py`](files/holdlog.py)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/02.1-disk-full/setup.sh
cd ~/labs/2.1
```

### Step 1: Look at the layout and the mounts a server uses.

```bash
ls /
findmnt -t ext4,xfs,tmpfs,vfat
df -h /
df -i /
```

Lab data lives in `$HOME`, not `/tmp`. On Ubuntu 26.04 `/tmp` is a tmpfs in RAM (systemd's `tmp.mount`, up to half of RAM, with a per-user quota); `/var/tmp` stays on disk. Check with `findmnt /tmp`.

### Step 2: Make a 200 MB filesystem in a file and mount it.

```bash
fallocate -l 200M disk.img
mkfs.ext4 -q -N 2000 disk.img
sudo mkdir -p /mnt/shikumi
sudo mount -o loop disk.img /mnt/shikumi
sudo chown "$USER": /mnt/shikumi
df -h /mnt/shikumi; df -i /mnt/shikumi
```

`-N 2000` asks for very few inodes, which step 6 uses.

### Step 3: In a second terminal, fill it from a process that keeps its log open.

```bash
python3 ~/labs/2.1/holdlog.py /mnt/shikumi/app.log
```

It stops with `No space left on device` and keeps running.

### Step 4: Back in the first terminal, delete the log, then look for the space.

```bash
rm /mnt/shikumi/app.log
df -h /mnt/shikumi
sudo du -sh /mnt/shikumi
lsof -a +L1 /mnt/shikumi
```

`df` still shows the disk full, `du` finds almost nothing, and `lsof -a +L1` lists the deleted file (link count 0) with its PID and FD number. `-a` matters: without it `lsof` ORs its selections and lists every deleted-but-open file on the system, plus everything open on `/mnt/shikumi`. `du` runs with sudo only because `lost+found` is root's. Recover the space without stopping the process by truncating it through `/proc`:

### Step 5: Recover the space, then stop holdlog.py.

```bash
PID=$(pgrep -f holdlog.py); ls -l /proc/$PID/fd
truncate -s 0 /proc/$PID/fd/3
df -h /mnt/shikumi
```

Then press Ctrl-C in the second terminal. In production, restarting or signalling the service to reopen its logs does the same.

### Step 6: Now run out of inodes while plenty of space is free.

```bash
mkdir /mnt/shikumi/many
for i in $(seq 1 2100); do : > /mnt/shikumi/many/f$i || break; done
df -h /mnt/shikumi; df -i /mnt/shikumi
rm -rf /mnt/shikumi/many
```

Writes fail with `No space left on device` while `df -h` shows free space. `df -i` shows why.

### Step 7: Look at links.

```bash
echo hello > /mnt/shikumi/a
ln /mnt/shikumi/a /mnt/shikumi/hard
ln -s /mnt/shikumi/a /mnt/shikumi/soft
ls -li /mnt/shikumi
rm /mnt/shikumi/a; cat /mnt/shikumi/hard; cat /mnt/shikumi/soft
```

The hard link shares the inode and survives; the symlink now points at nothing.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Same steps. Fedora also mounts `/tmp` as tmpfs.

> **Debian**
>
> Same steps. Debian 13 also mounts `/tmp` as tmpfs.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 2.1
```

- `/mnt/shikumi` is mounted and less than half full
- No deleted-but-open files remain on it (`lsof -a +L1 /mnt/shikumi` is empty)
- Inode use is below half (the `many` directory is gone)

## Stretch challenge

Find every deleted-but-open file on the whole VM with `sudo lsof +L1`. Which services hold one, and why is that usually harmless?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/02.1-disk-full/cleanup.sh
```

Stops holdlog.py, unmounts `/mnt/shikumi` and deletes the image. The script also removes `~/labs/2.1`.

## Coreutils used

`ls`, `df` (GNU), `du`, `truncate`, `seq`, `ln`, `rm` (GNU), `tail`, `tr`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
