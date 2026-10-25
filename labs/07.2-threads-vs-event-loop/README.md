# Lab 7.2: How servers wait: an event loop and a thread pool

**Module M07 · System calls and the kernel boundary** · about 25 min · [Lab index](../../README.md#lab-index)

**Goal:** Trace the asyncio service under load and see one thread waiting in `epoll_wait`, then trace a threaded server and see a new thread per connection.

## Before you start

- Lab 7.1 done.
- `shikumi-api@8001` running (Lab 5.4).

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/07.2-threads-vs-event-loop/setup.sh
cd ~/labs/7.2
```

### Step 1: Trace the asyncio instance for 15 seconds while you load it.

```bash
PID=$(systemctl show -p MainPID --value shikumi-api@8001)
sudo timeout 15 strace -f -tt -p "$PID" -o async.txt & T=$!
sleep 1
python3 ~/shikumi-linux-labs/app/loadgen.py 'http://127.0.0.1:8001/slow?ms=200' -c 10 -n 50
wait $T
grep -c epoll_wait async.txt
grep -m 3 accept4 async.txt
awk '{print $1}' async.txt | sort -u | wc -l
```

One thread serves all ten connections. It sleeps in `epoll_wait` until a socket is ready, and accepts with `accept4(..., SOCK_CLOEXEC)`. Python opens every descriptor close-on-exec, so the flag is always there. asyncio makes the new socket non-blocking with a separate call right after, so `SOCK_NONBLOCK` does not appear.

### Step 2: Trace a threaded server under the same load.

```bash
strace -f -o threads.txt \
  python3 ~/shikumi-linux-labs/app/threaded_api.py &
sleep 1
python3 ~/shikumi-linux-labs/app/loadgen.py \
  'http://127.0.0.1:8100/slow' -c 10 -n 50
pkill -f threaded_api.py; sleep 1
grep -c clone3 threads.txt
awk '{print $1}' threads.txt | sort -u | wc -l
```

Each connection gets a thread (`clone3`), and each thread blocks in its own `recvfrom` or `sleep`. That costs memory per connection, where the event loop costs one file descriptor.

### Step 3: Look at the io_uring switch.

```bash
sysctl kernel.io_uring_disabled 2>/dev/null || \
  echo "no io_uring_disabled switch on this kernel"
```

io_uring is completion-based: the program hands the kernel the I/O itself, not just a readiness question. Some systems turn it off by policy. Handout Appendix C1 has a minimal epoll server in C.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 7.2
```

- `async.txt` shows `epoll_wait` and `accept4`
- `threads.txt` shows `clone3` and more than five distinct thread IDs

## Stretch challenge

Run `loadgen.py -c 100` against both servers and compare `grep Threads /proc/PID/status` while it runs. No benchmark: just count threads.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/07.2-threads-vs-event-loop/cleanup.sh
```

Stops `threaded_api.py` and any strace left running.

## Coreutils used

`timeout`, `sort`, `wc`, `sleep`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): the strace steps show epoll_wait, accept4 and one clone3 per connection.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
