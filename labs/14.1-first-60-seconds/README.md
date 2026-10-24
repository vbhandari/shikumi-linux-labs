# Lab 14.1: The first 60 seconds

**Module M14 · Observability and troubleshooting** · about 25 min · [Lab index](../../README.md#lab-index)

**Goal:** Start a hidden problem, then name it (CPU, memory or I/O) in under five minutes with the standard first-look tools.

## Before you start

- Lab 13.4 done.
- The course packages installed (`sysstat` for `mpstat`, `pidstat`, `iostat`).

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/mystery.sh`](files/mystery.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/14.1-first-60-seconds/setup.sh
cd ~/labs/14.1
```

### Step 1: Start the mystery and the clock.

```bash
sudo ./mystery.sh; date
```

`setup.sh` copied `mystery.sh` from the lab's `files/` folder into `~/labs/14.1`. It takes `--reveal` and `--stop`, and runs the problem as the transient unit `shikumi-mystery`.

### Step 2: Take the first look.

```bash
uptime
vmstat 1 5
mpstat -P ALL 1 3
pidstat 1 5
iostat -xz 1 3
free -h
sudo journalctl -k -p warning --since '-10 min' --no-pager
ss -s
```

Work through the USE method: for CPU, memory and disk, check **u**tilisation, **s**aturation and **e**rrors. Load average counts tasks waiting in D state too, so a high load with idle CPUs points at I/O.

### Step 3: Name the problem.

```bash
echo cpu > answer.txt     # or memory, or io
~/shikumi-linux-labs/bin/shikumi-check lab 14.1
```

### Step 4: Reveal it, stop it, and go again.

```bash
sudo ./mystery.sh --reveal
sudo ./mystery.sh --stop
sudo ./mystery.sh
```

Repeat until you have seen all three. Which columns gave each one away first?

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 14.1
```

- `answer.txt` names the problem that is running now

## Stretch challenge

Find the culprit process for each kind, not just the resource: which `pidstat` flag (`-u`, `-r` or `-d`) points at it fastest?

## Cleanup

```bash
~/shikumi-linux-labs/labs/14.1-first-60-seconds/cleanup.sh
```

Stops the mystery unit and removes its files.

## Coreutils used

`date`, `tr`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
