# Lab 3.3: Run out of file descriptors

**Module M03 · Processes, signals and file descriptors** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Leak descriptors in the app until it fails with `OSError: [Errno 24] Too many open files`, then raise the limit and see the same request succeed.

## Before you start

- Lab 3.2 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/03.3-file-descriptors-and-limits/setup.sh
cd ~/labs/3.3
```

### Step 1: Look at your own descriptors and limits.

```bash
ls -l /proc/self/fd
ulimit -n; ulimit -Hn
```

0, 1 and 2 are stdin, stdout and stderr. The soft limit is what a process gets; it may raise it up to the hard limit.

### Step 2: Start the app with a soft limit of 64.

```bash
(ulimit -n 64; exec python3 ~/shikumi-linux-labs/app/shikumi_api.py --port 8000) & APP=$!
sleep 1
grep 'open files' /proc/$APP/limits
ls /proc/$APP/fd | wc -l
lsof -p $APP | tail -n 4
```

The listening socket is just another descriptor: `lsof` shows it as `TCP localhost:8000 (LISTEN)`.

### Step 3: Ask the app to hold 100 open files.

```bash
curl -s 'http://127.0.0.1:8000/files?n=100'; echo
ls /proc/$APP/fd | wc -l
curl -s -m 3 http://127.0.0.1:8000/healthz; echo "curl exit=$?"
```

The first request returns `OSError: [Errno 24] Too many open files`. The app now holds 63 of its 64 descriptors, and its output fills with `socket.accept() out of system resource` while it retries. `/healthz` probably still answers: one descriptor is free again once the failed request's socket closes, so new connections get in one at a time. Under real traffic most of them would wait or time out. A leak degrades the whole service, not one request.

### Step 4: Restart it with a higher limit and repeat.

```bash
kill $APP
(ulimit -n 4096; exec python3 ~/shikumi-linux-labs/app/shikumi_api.py --port 8000) & APP=$!
sleep 1
curl -s 'http://127.0.0.1:8000/files?n=100'; echo
kill $APP
```

Raising the limit only buys time: a real leak still grows. Lab 5.1 sets the limit for a service with `LimitNOFILE=`.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 3.3
```

- With `ulimit -n 64`, `/files?n=100` fails with `Errno 24`
- With `ulimit -n 4096`, the same request returns 200

## Stretch challenge

Find the process on the VM with the most open descriptors: `sudo ls /proc/*/fd 2>/dev/null` is a start; `sudo lsof -n | awk '{print $2}' | sort | uniq -c | sort -rn | head` is another.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/03.3-file-descriptors-and-limits/cleanup.sh
```

Stops any app you started.

## Coreutils used

`ls`, `wc`, `tail`, `sort`, `uniq`, `head`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): steps and checks pass.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
