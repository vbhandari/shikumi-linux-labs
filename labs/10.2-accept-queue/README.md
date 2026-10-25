# Lab 10.2: Fill the accept queue

**Module M10 · TCP for backend and test engineers** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Listen with a small backlog and never accept, fill the queue from a load generator, and watch the queue length and the overflow counter.

## Before you start

- Lab 10.1 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/10.2-accept-queue/setup.sh
cd ~/labs/10.2
```

### Step 1: Read the system's limits.

```bash
sysctl net.core.somaxconn net.ipv4.tcp_max_syn_backlog \
  net.ipv4.tcp_syncookies
```

`listen(backlog)` is capped at `somaxconn`.

### Step 2: Start a listener with backlog 8 that never accepts.

```bash
python3 ~/shikumi-linux-labs/app/acceptq.py --backlog 8 &
A=$!
sleep 1
ss -lnt 'sport = :8300'
```

For a listening socket, `Send-Q` is the queue limit (8) and `Recv-Q` the connections waiting in it now.

### Step 3: Throw 50 connections at it.

```bash
nstat -az TcpExtListenOverflows TcpExtListenDrops
python3 ~/shikumi-linux-labs/app/loadgen.py http://127.0.0.1:8300/ -c 50 -n 50 --timeout 3 | tee backlog8.txt &
sleep 1; ss -lnt 'sport = :8300'
wait
nstat -az TcpExtListenOverflows TcpExtListenDrops
```

`Recv-Q` stops at 9 (backlog + 1). The kernel drops further handshakes and counts them in `ListenOverflows`; clients retry their SYN, then time out.

### Step 4: Raise the backlog and repeat.

```bash
kill $A
python3 ~/shikumi-linux-labs/app/acceptq.py --backlog 64 & A=$!
sleep 1
python3 ~/shikumi-linux-labs/app/loadgen.py http://127.0.0.1:8300/ -c 50 -n 50 --timeout 3 | tee backlog64.txt &
sleep 1; ss -lnt 'sport = :8300'
wait; kill $A
nstat -az TcpExtListenOverflows
```

All 50 now fit in the queue and the counter stops rising. The requests still time out: a bigger queue only helps a server that does accept, just slowly.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 10.2
```

- `backlog8.txt` and `backlog64.txt` hold load-generator results
- A listener with backlog 8 shows `Send-Q 8` and fills to `Recv-Q 9`, and `ListenOverflows` rises (`check.sh` repeats this on port 8310)

## Stretch challenge

Check the backlog of the real services: `ss -lnt 'sport = :8001'`. Which value is it, and where in `shikumi_api.py` does it come from?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/10.2-accept-queue/cleanup.sh
```

Stops `acceptq.py` and removes `~/labs/10.2`.

## Coreutils used

`tee`, `sleep`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): steps and checks pass.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
