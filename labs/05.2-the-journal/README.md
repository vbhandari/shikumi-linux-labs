# Lab 5.2: Find the crash in the journal

**Module M05 · systemd and the journal** · about 15 min · [Lab index](../../README.md#lab-index)

**Goal:** Find Lab 5.1's crash by unit, by time and by priority, read one entry as JSON, and write your own log line.

## Before you start

- Lab 5.1 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/05.2-the-journal/setup.sh
cd ~/labs/5.2
```

### Step 1: Follow the service's log while you make a request.

```bash
sudo journalctl -u shikumi-api -f
```

In a second terminal run `curl -s http://127.0.0.1:8000/healthz`. Each request shows as `GET /healthz 200`. Press Ctrl-C to stop following.

### Step 2: Find the crash from Lab 5.1 by unit and by time.

```bash
sudo journalctl -u shikumi-api --since today --no-pager | grep -E 'Main process exited|Scheduled restart'
sudo journalctl -u shikumi-api --since "1 hour ago" --no-pager | tail -n 20
```

### Step 3: Find it by priority, and read one entry in full.

```bash
sudo journalctl -u shikumi-api -p warning --no-pager
sudo journalctl -b -p err --no-pager | tail -n 10
sudo journalctl -u shikumi-api -o json-pretty -n 1
```

Every entry carries structured fields such as `_PID`, `_SYSTEMD_UNIT` and `PRIORITY`. `-p warning` shows warning and anything more severe.

### Step 4: Write your own entry.

```bash
logger -t shikumi-lab -p user.notice "hello from lab 5.2"
sudo journalctl -t shikumi-lab --no-pager
grep shikumi-lab /var/log/syslog
```

On Ubuntu, rsyslog also copies messages to `/var/log/syslog`, which only group `adm` may read. If `grep` says `Permission denied`, you are not in `adm` yet: `vm/provision.sh` adds you, then log out and back in (or use `sudo grep`). The journal is the answer that works everywhere.

### Step 5: Check where the journal is stored.

```bash
ls /var/log/journal
journalctl --disk-usage
sudo journalctl --list-boots --no-pager | tail -n 3
```

`/var/log/journal` exists, so the journal is persistent and survives a reboot. `provision.sh` created it.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Fedora has no rsyslog by default and no `/var/log/syslog`: use the journal only.

> **Debian**
>
> Same as Fedora: journal only.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 5.2
```

- The journal is persistent (`/var/log/journal` exists)
- The journal holds `shikumi-api.service` entries, including a `Main process exited` line from the Lab 5.1 crash
- A `shikumi-lab` entry exists

## Stretch challenge

Show only the app's own output, without systemd's lines: filter on `_COMM=` or `_PID=` with `journalctl _SYSTEMD_UNIT=shikumi-api.service _COMM=...`. Which value does `_COMM` have, and why?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/05.2-the-journal/cleanup.sh
```

Nothing to undo.

## Coreutils used

`tail`, `ls`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
