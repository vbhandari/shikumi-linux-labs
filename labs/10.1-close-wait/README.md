# Lab 10.1: CLOSE_WAIT is an application bug

**Module M10 · TCP for backend and test engineers** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Run a server that never closes its sockets, watch CLOSE_WAIT grow, and fix the code.

## Before you start

- Lab 9.3 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/10.1-close-wait/setup.sh
cd ~/labs/10.1
```

### Step 1: Start the buggy server and send it 20 requests.

```bash
python3 closewait.py & S=$!
sleep 1
for i in $(seq 1 20); do
  curl -s -m 2 http://127.0.0.1:8200/ >/dev/null
done
ss -tan state close-wait '( sport = :8200 )' | tail -n 3
ss -Htan state close-wait '( sport = :8200 )' | wc -l
ls /proc/$S/fd | wc -l
```

Every client sent FIN and the kernel acknowledged it, but the program never called `close()`. Each socket stays in CLOSE_WAIT and keeps a file descriptor until the process exits.

### Step 2: Look at the client side.

```bash
ss -tan state fin-wait-2 '( dport = :8200 )' | head -n 3
```

The clients wait in FIN_WAIT_2 for a FIN that never comes; the kernel gives up on them after about a minute. A normal close leaves TIME_WAIT on whichever side closed first, which is harmless.

### Step 3: Fix the code.

```bash
kill $S
${EDITOR:-nano} closewait.py
```

Close the connection once the response is sent, in every case. Then start it again and leave it running for the check:

```bash
python3 closewait.py &
for i in $(seq 1 20); do
  curl -s -m 2 http://127.0.0.1:8200/ >/dev/null
done
ss -Htan state close-wait '( sport = :8200 )' | wc -l
```

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 10.1
```

- Your fixed `closewait.py` is running on port 8200
- After 20 requests, no socket on port 8200 is in CLOSE_WAIT

## Stretch challenge

Use `with conn:` instead of an explicit `close()`. Then make a request time out on the server side (`conn.settimeout`) so a client that never sends anything cannot hold a socket forever.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/10.1-close-wait/cleanup.sh
```

Stops `closewait.py`.

## Coreutils used

`seq`, `tail`, `wc`, `ls`, `head`, `tr`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): steps and checks pass.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
