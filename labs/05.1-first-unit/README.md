# Lab 5.1: Install the app as a systemd service

**Module M05 · systemd and the journal** · about 25 min · [Lab index](../../README.md#lab-index)

**Goal:** Install the app to `/opt/shikumi/bin/shikumi-api`, run it as the `shikumi` user from a unit file, watch systemd restart it after a crash, and raise its file limit with a drop-in.

## Before you start

- Lab 4.1 done (port 80 free; nginx disabled).
- The `shikumi` user from Lab 2.2 (setup creates it if missing).

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/limits.conf`](files/limits.conf)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/05.1-first-unit/setup.sh
cd ~/labs/5.1
```

### Step 1: Install the app and its settings with fixed modes.

```bash
sudo install -d /opt/shikumi/bin /etc/shikumi
sudo install -m 0755 \
  ~/shikumi-linux-labs/app/shikumi_api.py \
  /opt/shikumi/bin/shikumi-api
sudo install -m 0644 \
  ~/shikumi-linux-labs/units/shikumi-api.env /etc/shikumi/
ls -l /opt/shikumi/bin
cat /etc/shikumi/shikumi-api.env
```

### Step 2: Read the unit, check it, install it and start it.

```bash
cat ~/shikumi-linux-labs/units/shikumi-api.service
sudo install -m 0644 ~/shikumi-linux-labs/units/shikumi-api.service /etc/systemd/system/
systemd-analyze verify /etc/systemd/system/shikumi-api.service
sudo systemctl daemon-reload
sudo systemctl enable --now shikumi-api
systemctl status shikumi-api --no-pager
curl -s http://127.0.0.1:8000/healthz; echo
```

`Type=notify` makes `systemctl start` wait until the app reports that it is ready: once its socket is listening, it sends `READY=1` to the socket systemd names in `$NOTIFY_SOCKET`. That is why the `curl` straight after `enable --now` gets an answer. `MemoryHigh=`, `MemoryMax=` and `TasksMax=` cap what the service may use, so a leak cannot take the VM down; Lab 8.3 shows what happens at the cap. With `Type=exec`, systemd would report success as soon as the program had started, before Python was listening. `StateDirectory=shikumi` creates `/var/lib/shikumi`, owned by `shikumi`.

### Step 3: Give the app a file to serve.

```bash
echo "hello from /var/lib/shikumi" | sudo -u shikumi tee /var/lib/shikumi/hello.txt
curl -s 'http://127.0.0.1:8000/data?name=hello.txt'; echo
```

### Step 4: Crash it and watch systemd bring it back.

```bash
systemctl show -p MainPID,NRestarts shikumi-api
sudo kill -KILL "$(systemctl show -p MainPID --value shikumi-api)"
sleep 2
systemctl show -p MainPID,NRestarts shikumi-api
sudo systemctl stop shikumi-api; systemctl is-active shikumi-api
sudo systemctl start shikumi-api
```

`Restart=on-failure` restarts after a crash or a kill by signal, but not after `systemctl stop`.

### Step 5: Raise the file limit with a drop-in.

```bash
sudo install -D -m 0644 limits.conf /etc/systemd/system/shikumi-api.service.d/limits.conf
sudo systemctl daemon-reload
sudo systemctl restart shikumi-api
systemctl cat shikumi-api
grep 'open files' /proc/"$(systemctl show -p MainPID --value shikumi-api)"/limits
```

`sudo systemctl edit shikumi-api` writes the same kind of file interactively, as `override.conf`. A drop-in changes a unit without editing the shipped file.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Use `install` or `cp` from your home directory, never `mv`. A moved file keeps its SELinux home-directory label and systemd cannot run it (`status=203/EXEC`). Fix a moved file with `sudo restorecon -v /opt/shikumi/bin/shikumi-api`. *(to verify)*

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 5.1
```

- `/opt/shikumi/bin/shikumi-api` is mode 0755 and owned by root
- `shikumi-api.service` is enabled and active, runs as `shikumi`, and `/healthz` on port 8000 returns 200
- `/data?name=hello.txt` returns 200
- The running process has `Max open files 4096`

## Stretch challenge

Make the service fail to start on purpose (`ExecStart=/opt/shikumi/bin/missing` in a drop-in), read `systemctl status`, then remove the drop-in. What does `Restart=` do when the program cannot even start?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/05.1-first-unit/cleanup.sh
```

Removes only the `LimitNOFILE` drop-in. The service stays installed and running: the rest of the course builds on it. `bin/shikumi-reset` removes it at the end of the course. The script also removes `~/labs/5.1`.

## Coreutils used

`install`, `ls`, `cat`, `stat`, `sleep`, `tee`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): the units pass systemd-analyze verify (systemd 259).

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
