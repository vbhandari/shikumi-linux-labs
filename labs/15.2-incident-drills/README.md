# Lab 15.2: Incident drills

**Module M15 · Capstone: run it, break it, fix it** · about 45 min · [Lab index](../../README.md#lab-index)

**Goal:** Inject seven faults into the Lab 15.1 stack one at a time, diagnose each with the tools from the course, fix it, and let the check confirm the stack is healthy again.

## Before you start

- Lab 15.1 done and its check passing, with the `stack` snapshot taken.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/15.2-incident-drills/setup.sh
cd ~/labs/15.2
```

### Step 1: Confirm the stack is healthy before you start.

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 15.2
```

### Step 2: Inject a fault.

```bash
sudo ~/shikumi-linux-labs/labs/15.2-incident-drills/break.sh 1
```

`break.sh` sits at the lab's root and runs from the repo; it is not copied to `~/labs`. It takes a drill number, 1 to 7, or `--undo`. After each fix, `shikumi-check lab 15.2` runs this lab's `check.sh` against the whole stack. Do not read `break.sh` until you have fixed the fault: the point is to find it from symptoms. Start from what a user would see:

```bash
curl -s --cacert /etc/nginx/shikumi-tls/ca.crt https://localhost/healthz
python3 ~/shikumi-linux-labs/app/loadgen.py http://127.0.0.1:8001/healthz -n 50 --timeout 1
```

### Step 3: Diagnose and fix it.

Work outwards from the symptom with the tools from the course: the journal (`journalctl -u 'shikumi-api@*' -k -p warning`), `systemctl status` and `systemctl list-units 'shikumi-*'`, `ss`, `lsof`, `df` and `findmnt`, `top` and `pidstat`, `perf`, `tc`, `aa-status`. Each fault is something an earlier lab taught, and each one shows up as a symptom first: errors, slow answers, or a check that fails.

Fix the cause, not just the symptom, and leave `--undo` for when you are stuck. Write down what you saw, what you ran and what fixed it: that note is the real output of this lab.

### Step 4: Confirm the fix.

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 15.2
```

Then inject the next fault, 2 to 7. If you are stuck, `sudo .../break.sh --undo` removes every fault.

> **Fedora / RHEL-family (alternate path, untested)**
>
> `break.sh` targets Ubuntu only, so the drills don't run on Fedora.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 15.2
```

- Both instances are active, answer `/data` with 200, and `https://localhost/healthz` answers 200
- Every drill you injected reads `fault N cleared`
- p50 latency to `@8001` is below 50 ms

## Stretch challenge

Write drill 8 yourself: a fault the course taught but `break.sh` does not inject (an expired certificate, a full inode table, a missing ufw rule). Add it to a copy of `break.sh` and to `check.sh`, and hand it to someone else.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/15.2-incident-drills/cleanup.sh
```

Undoes every drill (`break.sh --undo`). The Lab 15.1 stack stays. To remove everything, run `~/shikumi-linux-labs/bin/shikumi-reset` or restore the `clean` snapshot. The script also removes `~/labs/15.2`.

## Coreutils used

`install`, `wc`, `tail`, `tr`, `cut`, `df` (GNU). On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
