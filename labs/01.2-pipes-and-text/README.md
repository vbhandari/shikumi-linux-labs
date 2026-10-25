# Lab 1.2: Answer five questions from an access log

**Module M01 · Shell fluency** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Use pipes, `grep`, `awk`, `sort` and `uniq -c` to answer questions about a web access log, and record the answers.

## Before you start

- Lab 1.1 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/answers.txt`](files/answers.txt)
- [`files/make_log.py`](files/make_log.py)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/01.2-pipes-and-text/setup.sh
cd ~/labs/1.2
```

### Step 1: Generate the log and look at its shape.

```bash
python3 make_log.py
head -3 access.log
wc -l access.log
```

Fields, split on spaces: `$1` client IP, `$7` path, `$9` status, `$10` bytes, `$11` response time in seconds.

### Step 2: How many requests are there in total?

```bash
wc -l < access.log
```

### Step 3: How many responses were server errors (5xx)?

```bash
awk '$9 >= 500' access.log | wc -l
```

### Step 4: Which path was requested most, and which client sent the most requests?

```bash
awk '{print $7}' access.log | sort | uniq -c | sort -rn | head -3
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -3
```

### Step 5: Which path had the single slowest response?

```bash
sort -k11,11 -rn access.log | head -1
```

### Step 6: Write the five answers into `answers.txt`, then see stdout and stderr apart.

```bash
${EDITOR:-nano} answers.txt
grep -c . access.log /nonexistent 2>errors.txt | tee counts.txt
cat errors.txt
```

`2>` sends stderr to a file, `tee` copies stdout to a file and the screen. `2>&1` would merge them.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 1.2
```

- Each of the five answers matches what `check.sh` computes from your `access.log`

## Stretch challenge

Convert the log to JSON lines with `awk` and answer question 2 again with `jq`: `jq -s 'map(select(.status >= 500)) | length'`.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/01.2-pipes-and-text/cleanup.sh
```

Removes `~/labs/1.2`.

## Coreutils used

`head`, `wc`, `sort`, `uniq`, `tee`, `cat`, `tr`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): setup, steps and checks pass.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
