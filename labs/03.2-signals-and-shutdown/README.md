# Lab 3.2: Graceful shutdown, KILL, and a zombie

**Module M03 · Processes, signals and file descriptors** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Show that TERM lets an in-flight request finish while KILL cuts it off, read the 128+n exit codes, trap signals in a script, and reap a zombie.

## Before you start

- Lab 3.1 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/trap.sh`](files/trap.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/03.2-signals-and-shutdown/setup.sh
cd ~/labs/3.2
```

### Step 1: Send TERM while a slow request is in flight.

```bash
python3 ~/shikumi-linux-labs/app/shikumi_api.py --port 8000 & APP=$!
sleep 1
curl -s 'http://127.0.0.1:8000/slow?ms=3000' & CURL=$!
sleep 0.5; kill -TERM $APP
wait $CURL; echo "curl exit=$?"
wait $APP; echo "app exit=$?"
```

The request completes, the app prints `stopped, 0 request(s) cut off`, and both exit 0. The app's TERM handler stops accepting and waits for in-flight work.

### Step 2: Do the same with KILL.

```bash
python3 ~/shikumi-linux-labs/app/shikumi_api.py --port 8000 & APP=$!
sleep 1
curl -s 'http://127.0.0.1:8000/slow?ms=3000' & CURL=$!
sleep 0.5; kill -KILL $APP
wait $CURL; echo "curl exit=$?"
wait $APP; echo "app exit=$?"
```

curl exits 52 (empty reply) and the app's status is 137, which is 128 + 9 (SIGKILL). No handler ran.

### Step 3: Trap signals in a script.

```bash
./trap.sh & T=$!
sleep 1; kill -TERM $T; wait $T; echo "exit=$?"
```

### Step 4: Make a zombie and reap it.

```bash
python3 ~/shikumi-linux-labs/app/zombie.py
```

In a second terminal, run the `ps` command it prints: the child shows state `Z` and `<defunct>`. Press Enter in the first terminal; the parent calls `waitpid` and the zombie is gone. If a parent never reaps, its zombies stay until the parent exits and PID 1 adopts and reaps them.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 3.2
```

- TERM during a request: the request succeeds and the app exits 0
- KILL during a request: the app's exit status is 137
- No `zombie.py` or `trap.sh` process is left running

## Stretch challenge

Run `sleep 600 &` then `kill -HUP` it and read `$?` after `wait`. Which number do you get and why? Look up the signal numbers with `kill -l`.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/03.2-signals-and-shutdown/cleanup.sh
```

Stops any app, `trap.sh` or `zombie.py` you started.

## Coreutils used

`sleep`, `seq`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): steps and checks pass.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
