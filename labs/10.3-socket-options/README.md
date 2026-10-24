# Lab 10.3: SO_REUSEPORT, SO_REUSEADDR and EADDRINUSE

**Module M10 · TCP for backend and test engineers** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Share one port between two processes with `SO_REUSEPORT`, see the options with strace, and reproduce and fix `EADDRINUSE`.

## Before you start

- Lab 10.2 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/bind_test.py`](files/bind_test.py)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/10.3-socket-options/setup.sh
cd ~/labs/10.3
```

### Step 1: Start two listeners on the same port.

```bash
python3 ~/shikumi-linux-labs/app/shikumi_api.py \
  --port 8400 --reuseport & A=$!
python3 ~/shikumi-linux-labs/app/shikumi_api.py \
  --port 8400 --reuseport & B=$!
sleep 1
ss -ltnp 'sport = :8400'
python3 ~/shikumi-linux-labs/app/loadgen.py \
  http://127.0.0.1:8400/healthz -c 20 -n 200 --by-pid | \
  tee reuseport.txt
```

The kernel spreads new connections across both sockets by a hash of the connection, so `by_pid` shows two PIDs with roughly equal counts.

### Step 2: See the options being set.

```bash
strace -f -e trace=setsockopt,bind,listen python3 ~/shikumi-linux-labs/app/shikumi_api.py --port 8401 --reuseport &
sleep 1; pkill -f 'shikumi_api.py --port 8401'
```

### Step 3: Start a third listener without --reuseport.

```bash
python3 ~/shikumi-linux-labs/app/shikumi_api.py --port 8400
kill $A $B
```

It fails with `OSError: [Errno 98] Address already in use`: every socket on a port must agree to share it.

### Step 4: Rebind a port that has a connection in TIME_WAIT.

```bash
python3 bind_test.py
ss -tan state time-wait '( sport = :8410 )'
```

Without `SO_REUSEADDR` the bind fails while the old connection is in TIME_WAIT. This is why a server restarted quickly says *Address already in use*, and why servers set `SO_REUSEADDR`.

### Step 5: Look at the other options and limits that bite test rigs.

```bash
sysctl net.ipv4.tcp_keepalive_time net.ipv4.ip_local_port_range
ss -Htan state time-wait | wc -l
```

Keepalive waits two hours by default before probing an idle connection. A client that opens connections faster than TIME_WAIT expires can run out of local ports. `TCP_NODELAY` turns off Nagle's algorithm, which otherwise holds back small writes.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 10.3
```

- `reuseport.txt` shows responses from two PIDs
- `bind_test.py` fails without `SO_REUSEADDR` and succeeds with it

## Stretch challenge

Stop one of the two listeners in step 1 halfway through a `loadgen.py` run. Do any requests fail? What would a graceful handover need?

## Cleanup

```bash
~/shikumi-linux-labs/labs/10.3-socket-options/cleanup.sh
```

Stops any listener on ports 8400 and 8401.

## Coreutils used

`tee`, `wc`, `sleep`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): steps and checks pass.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
