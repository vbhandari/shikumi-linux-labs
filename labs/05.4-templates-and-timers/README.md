# Lab 5.4: Two instances from one template, and a timer

**Module M05 · systemd and the journal** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Run `shikumi-api@8001` and `shikumi-api@8002` from one template unit, and add a timer that prunes old temporary files.

## Before you start

- Lab 5.3 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/05.4-templates-and-timers/setup.sh
cd ~/labs/5.4
```

### Step 1: Install the template with the same hardening drop-in, and start two instances.

```bash
cat ~/shikumi-linux-labs/units/shikumi-api@.service
sudo install -m 0644 ~/shikumi-linux-labs/units/shikumi-api@.service /etc/systemd/system/
sudo install -D -m 0644 ~/shikumi-linux-labs/units/hardening.conf /etc/systemd/system/shikumi-api@.service.d/hardening.conf
sudo systemctl daemon-reload
sudo systemctl enable --now shikumi-api@8001 shikumi-api@8002
systemctl list-units 'shikumi-api*' --no-pager
curl -s http://127.0.0.1:8001/healthz; echo; curl -s http://127.0.0.1:8002/healthz; echo
```

`%i` is the text after `@`, here the port. Each instance is its own process with its own PID.

### Step 2: See how the template expands.

```bash
systemctl cat shikumi-api@8001 --no-pager | \
  grep -E 'ExecStart|^#'
systemctl show -p ExecStart shikumi-api@8002
```

### Step 3: Install the prune service and its timer.

```bash
cat ~/shikumi-linux-labs/units/shikumi-prune.service \
  ~/shikumi-linux-labs/units/shikumi-prune.timer
sudo install -m 0644 \
  ~/shikumi-linux-labs/units/shikumi-prune.{service,timer} \
  /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now shikumi-prune.timer
systemctl list-timers shikumi-prune.timer --no-pager
```

The VM booted more than 5 minutes ago, so `OnBootSec=5min` has already passed and the prune job runs as soon as the timer starts. Right afterwards `list-timers` may show `NEXT` as `-`; run it again and the next run is 15 minutes after the last one (`OnUnitActiveSec=15min`).

### Step 4: Test the prune job without waiting for the timer.

```bash
sudo -u shikumi touch -d '2 hours ago' /var/lib/shikumi/old.tmp
sudo -u shikumi touch /var/lib/shikumi/new.tmp
sudo systemctl start shikumi-prune.service
sudo journalctl -u shikumi-prune -n 5 --no-pager
ls /var/lib/shikumi
```

Only `old.tmp` is deleted. Unlike cron, a timer's runs are in the journal. A calendar timer (`OnCalendar=`) with `Persistent=true` also catches up on a run missed while the VM was off. `Persistent=` applies only to `OnCalendar=`, so this timer, which counts from boot and from its last run, does not need it.

### Step 5: Compare with cron, and look at socket units.

```bash
crontab -l 2>/dev/null || echo "no user crontab"
systemctl list-timers --all --no-pager | head -n 8
systemctl list-sockets --no-pager | head -n 8
```

Socket activation lets systemd hold the listening socket and start the service on the first connection. The course app does not use it.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 5.4
```

- `shikumi-api@8001` and `@8002` are enabled and active, answer 200, and have different PIDs
- `shikumi-prune.timer` is enabled and active
- The last `shikumi-prune.service` run succeeded and `old.tmp` is gone

## Stretch challenge

Change the timer to run every 5 minutes with a drop-in (`OnUnitActiveSec=` must be reset with an empty line first), and confirm with `systemctl list-timers`.

## Cleanup

```bash
~/shikumi-linux-labs/labs/05.4-templates-and-timers/cleanup.sh
```

Removes the test `.tmp` files. The instances and the timer stay for later labs.

## Coreutils used

`install`, `cat`, `touch -d`, `ls`, `head`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): the template and timer pass systemd-analyze verify.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
