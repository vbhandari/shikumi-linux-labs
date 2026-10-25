# Lab 3.1: Profile a process through /proc, and watch fork and exec

**Module M03 · Processes, signals and file descriptors** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Start the app, read everything the kernel knows about it in `/proc`, move a process through its states, and watch a shell fork and exec.

## Before you start

- Lab 2.3 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/03.1-what-a-process-is/setup.sh
cd ~/labs/3.1
```

### Step 1: Start the app in the background and find it.

```bash
python3 ~/shikumi-linux-labs/app/shikumi_api.py --port 8000 & APP=$!
ps -o pid,ppid,stat,user,cmd -p $APP
ps -ef --forest | grep -B1 -A0 shikumi_api
```

### Step 2: Read its /proc entry.

```bash
head -n 12 /proc/$APP/status
tr '\0' ' ' < /proc/$APP/cmdline; echo
ls -l /proc/$APP/exe /proc/$APP/cwd
ls -l /proc/$APP/fd
grep -E 'open files|processes' /proc/$APP/limits
cat /proc/$APP/status > status.txt
```

`exe` points at the Python interpreter, not the script: the script is only an argument. On Ubuntu 26.04, `ls -l` (uutils) prints a stray `+` after the mode of the socket links, as in `lrwx------+1`. That is a display quirk, not an ACL: `gnuls -l /proc/$APP/fd` shows the GNU view.

### Step 3: Move a process through its states.

```bash
sleep 300 & S=$!
ps -o pid,stat,cmd -p $S
kill -STOP $S; ps -o pid,stat,cmd -p $S
kill -CONT $S; kill $S
top -b -n 1 | head -n 15
```

`S` is sleeping, `T` stopped. `R` is running, `D` waiting on I/O (it cannot be interrupted) and `Z` a zombie, which Lab 3.2 makes.

### Step 4: Watch a shell fork and exec.

```bash
strace -f -o fork.txt -e trace=clone,clone3,execve bash -c 'ls /proc/self >/dev/null; python3 --version'
grep -E 'clone|execve' fork.txt
```

bash clones itself to run `ls`, then runs `python3`, its last command, by exec without a fork. No sudo is needed to trace a program you start.

### Step 5: Stop the app.

```bash
kill $APP
```

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 3.1
```

- `status.txt` holds the app's `/proc/PID/status` (it has a `PPid:` line)
- `fork.txt` shows `clone` (or `clone3`) and `execve` calls

## Stretch challenge

Find the process with the most threads on the VM: `ps -eo nlwp,pid,cmd --sort=-nlwp | head`. Then list its threads in `/proc/PID/task`.

## Cleanup

```bash
~/shikumi-linux-labs/labs/03.1-what-a-process-is/cleanup.sh
```

Stops any app you started and removes `~/labs/3.1`.

## Coreutils used

`head`, `tr`, `ls`, `cat`, `sleep`, `kill` (shell builtin). On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): steps and checks pass.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
