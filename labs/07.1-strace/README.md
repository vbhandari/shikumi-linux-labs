# Lab 7.1: Watch system calls with strace

**Module M07 · System calls and the kernel boundary** · about 25 min · [Lab index](../../README.md#lab-index)

**Goal:** Trace curl and the app's startup, find the first config file Python looks for, count the system calls behind one request, and see how errno becomes a Python exception.

## Before you start

- Lab 6.2 done (the service is running on port 8000).

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/buffering.py`](files/buffering.py)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/07.1-strace/setup.sh
cd ~/labs/7.1
```

### Step 1: Trace a client.

```bash
strace -f -o curl.txt -e trace=file,network curl -s http://127.0.0.1:8000/healthz; echo
grep -E 'socket|connect|sendto|recvfrom' curl.txt | head
```

No sudo: you may trace programs you start yourself.

### Step 2: Trace the app's startup, with timestamps and durations.

```bash
strace -f -tt -T -e trace=file -o startup.txt python3 ~/shikumi-linux-labs/app/shikumi_api.py --port 8700 &
sleep 2; pkill -f 'shikumi_api.py --port 8700'; sleep 1
grep -m 3 -n -E '\.cfg|\.conf' startup.txt
grep -c ENOENT startup.txt
```

The first config file Python looks for is `pyvenv.cfg`, and it is not there (`ENOENT`). Most of the failed lookups are the import system searching its path.

### Step 3: Count the system calls behind one request to the running service.

```bash
PID=$(systemctl show -p MainPID --value shikumi-api)
sudo strace -c -f -p "$PID" -o count.txt & sleep 1
curl -s http://127.0.0.1:8000/healthz; echo
sleep 1; sudo pkill -INT -f "strace -c -f -p $PID"; sleep 1
cat count.txt
```

Attaching to a running process needs `sudo` on Ubuntu, because `kernel.yama.ptrace_scope` is 1.

### Step 4: See how errno becomes an exception.

```bash
strace -e trace=openat cat /etc/shadow 2>&1 | tail -n 3
python3 -c 'open("/etc/shadow")' 2>&1 | tail -n 1
python3 -c 'import errno, os; print(errno.errorcode[13], os.strerror(13))'
```

### Step 5: See output buffering.

```bash
python3 buffering.py | cat
python3 -u buffering.py | cat
strace -e trace=write -o writes.txt python3 buffering.py > /dev/null; grep -c 'write(1' writes.txt
```

Writing to a pipe, Python buffers and makes one `write` at exit; `-u` (or `flush=True`) makes one per line. This is why a service's log lines can arrive late.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 7.1
```

- `curl.txt` shows a `connect` to port 8000
- `startup.txt` shows the lookup of `pyvenv.cfg`
- `count.txt` holds a syscall summary (a `total` line)

## Stretch challenge

Trace the app while it fails a request: run `strace -f -e trace=openat` on a copy of the app with `--data-dir /nonexistent`, request `/data`, and match the `ENOENT` to the error the client sees.

## Cleanup

```bash
~/shikumi-linux-labs/labs/07.1-strace/cleanup.sh
```

Stops any leftover app on port 8700 or strace you started, and removes `~/labs/7.1`.

## Coreutils used

`head`, `tail`, `cat`, `sleep`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): the strace steps produce the expected files.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
