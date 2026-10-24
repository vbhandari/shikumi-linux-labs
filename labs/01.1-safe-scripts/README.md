# Lab 1.1: Make a deploy script fail loudly

**Module M01 · Shell fluency** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Fix a short bash deploy script so that a bad argument stops it with an error instead of silently deleting the live site.

## Before you start

- Lab 0.1 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/deploy.sh`](files/deploy.sh)
- [`files/releases/v2/index.html`](files/releases/v2/index.html)
- [`files/site/current/important.txt`](files/site/current/important.txt)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/01.1-safe-scripts/setup.sh
cd ~/labs/1.1
```

### Step 1: Run the script with a good release, then look at the result.

```bash
./deploy.sh v2; echo "exit status: $?"
ls site/current
```

It works, and wipes `important.txt` in the process. That is how this script is meant to replace a release.

### Step 2: Put the live file back and run it with a release that does not exist.

```bash
cp ~/shikumi-linux-labs/labs/01.1-safe-scripts/files/site/current/important.txt site/current/
./deploy.sh v3; echo "exit status: $?"
ls site/current
```

`cp` fails, but `rm` has already run, and the last command, `echo`, succeeds. The script reports success and the live site is empty.

### Step 3: Ask shellcheck what it sees.

```bash
shellcheck deploy.sh
```

### Step 4: Fix the script.

```bash
${EDITOR:-nano} deploy.sh
```

Add `set -euo pipefail`, quote every expansion, require exactly one argument, and check that `releases/$release` exists **before** touching `site/current`. Run `shellcheck deploy.sh` until it is silent.

### Step 5: Test your fix.

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 1.1
```

The check runs your `deploy.sh` against a scratch copy of the files, so it never touches `~/labs/1.1/site`. Running `setup.sh` again overwrites `deploy.sh`, so copy your fix aside first.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 1.1
```

- `shellcheck` reports nothing for your `deploy.sh`
- `./deploy.sh v3` exits non-zero and `important.txt` is still there
- `./deploy.sh v2` exits 0 and deploys `index.html`

## Stretch challenge

Make the deploy atomic: copy the release into `site/next`, then swap it into place with `mv -T` (GNU `mv` on Ubuntu 26.04), so a reader never sees a half-copied release.

## Cleanup

```bash
~/shikumi-linux-labs/labs/01.1-safe-scripts/cleanup.sh
```

Removes `~/labs/1.1`.

## Coreutils used

`ls`, `cp`, `rm`, `mktemp`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): setup, steps and checks pass; the check fails as expected before the fix.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
