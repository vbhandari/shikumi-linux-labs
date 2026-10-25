# Lab 14.2: Prove a deadlock and fix the lock order

**Module M14 · Observability and troubleshooting** · about 25 min · [Lab index](../../README.md#lab-index)

**Goal:** Let `deadlock.py` hang, prove from outside that its threads wait on each other's locks, dump every thread's stack without stopping it, and fix the lock order.

## Before you start

- Lab 14.1 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/14.2-hangs-and-deadlocks/setup.sh
cd ~/labs/14.2
```

### Step 1: Run it until the counter stops.

```bash
python3 deadlock.py 2> stacks.txt
```

`transfers=` grows for about two seconds, then freezes when `report()` first takes its locks. Leave it hung.

### Step 2: In a second terminal, look at its threads.

```bash
cd ~/labs/14.2
PID=$(pgrep -f 'deadlock.py' | head -n1)
ps -L -o tid,stat,pcpu,comm -p "$PID"
for t in /proc/$PID/task/*; do
  echo "$(cat "$t/comm") $(cat "$t/wchan")"
done
```

A new terminal starts in your home directory, hence the `cd`: step 4 reads `stacks.txt` here. Every thread sleeps (`S`) using no CPU. A hang with idle CPU means waiting, not working. `wchan` names the kernel function each thread waits in: the main thread in a sleep (`hrtimer_nanosleep`), the two workers in a futex wait (`futex_do_wait` on Ubuntu 26.04's kernel).

### Step 3: See the waits as system calls.

```bash
sudo timeout 5 strace -f -p "$PID" -e trace=futex
```

Each worker thread sits in one `futex` call that never returns. `sudo` is needed to attach because of the ptrace rules.

### Step 4: Dump every thread's Python stack.

```bash
kill -USR1 "$PID"
cat stacks.txt
```

`faulthandler` prints each thread's stack on SIGUSR1 without stopping the process. `transfer` waits on `audit_log` while holding `accounts`; `report` waits on `accounts` while holding `audit_log`. That is lock-order inversion.

### Step 5: Fix the lock order.

```bash
kill "$PID"
${EDITOR:-nano} deadlock.py
```

Make `report()` take the locks in the same order as `transfer()`. Run it again: `transfers=` keeps growing. `python3 deadlock.py --fixed` is the reference fix. Handout Appendix C2 shows the same bug in C, debugged with `gdb`.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 14.2
```

- `stacks.txt` holds the dumped stacks of the `transfer` and `report` threads
- Your `deadlock.py`, run without `--fixed`, keeps counting for six seconds

## Stretch challenge

Install `py-spy` in a virtual environment (`python3 -m venv ~/venv && ~/venv/bin/pip install py-spy`) and compare `sudo ~/venv/bin/py-spy dump --pid PID` with the faulthandler output.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/14.2-hangs-and-deadlocks/cleanup.sh
```

Stops any `deadlock.py` and removes `~/labs/14.2`.

## Coreutils used

`cat`, `head`, `tail`, `cut`, `timeout`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): steps and checks pass.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
