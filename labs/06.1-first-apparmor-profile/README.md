# Lab 6.1: Generate an AppArmor profile for the app

**Module M06 · Mandatory access control: AppArmor (core) · SELinux (alternate)** · about 30 min · [Lab index](../../README.md#lab-index)

**Goal:** Build an AppArmor profile for `/opt/shikumi/bin/shikumi-api` with `aa-genprof`, enforce it, and watch it refuse a file that Unix permissions allow.

## Before you start

- Lab 5.4 done.
- Take a VM snapshot first (`multipass snapshot`, `vagrant snapshot save`, or your cloud provider's console).
- Paste one block at a time. After `sudo systemctl start` or `aa-complain`, wait for the prompt before you paste more: lines typed ahead while they run can be lost.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/data-dir.conf`](files/data-dir.conf)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/06.1-first-apparmor-profile/setup.sh
cd ~/labs/6.1
```

### Step 1: Look at what is confined now.

```bash
sudo aa-status | head -n 12
ps -eZ | grep -v unconfined | head
ls /etc/apparmor.d | grep -c nginx
```

Profiles attach to an executable path. Ubuntu ships no nginx profile, so nginx would run unconfined; we profile our own app instead.

### Step 2: Stop every instance of the app.

```bash
sudo systemctl stop shikumi-api shikumi-api@8001 shikumi-api@8002
```

### Step 3: Start the profile generator.

```bash
sudo aa-genprof /opt/shikumi/bin/shikumi-api
```

It puts an empty profile in complain mode and waits. Leave it at its prompt.

### Step 4: In a second terminal, start the service and exercise it.

```bash
sudo systemctl start --no-block shikumi-api
sleep 1
curl -s http://127.0.0.1:8000/healthz; echo
curl -s 'http://127.0.0.1:8000/data?name=hello.txt'; echo
curl -s 'http://127.0.0.1:8000/files?n=3'; echo
sudo systemctl stop shikumi-api
```

Run it as the real service, so the profile sees what the service does. `--no-block` returns at once: under the new, empty profile the service cannot send its `READY=1` message yet (step 6 explains why), so a plain `start` would hang for 15 seconds and fail. The app is listening anyway, so the requests work. `/data?name=NAME` reads `NAME` from the data directory, `/var/lib/shikumi` unless `SHIKUMI_DATA_DIR` or `--data-dir` says otherwise; `setup.sh` put `hello.txt` there. Names that leave the directory get 400. Step 8 moves the data directory to `/srv/shikumi-data`, outside the profile.

### Step 5: Back in aa-genprof, press S to scan, then answer the prompts.

- `owner /var/lib/shikumi/hello.txt r`: choose **(G)lob** until it reads `/var/lib/shikumi/*`, then **(A)llow**.
- `/opt/shikumi/bin/ r`, the app's own directory: **(A)llow**.
- Network: aa-genprof offers abstractions, with `abstractions/apache2-common` as the default, plus `nameservice` and `passt`, and a specific `network inet stream` rule. Pick the specific rule; the default works but allows much more than the app needs.

There is no prompt for Python: aa-genprof adds `/usr/bin/python3.14 ix` (inherit) by itself. There is no prompt for the notify socket either; step 6 explains why.

Press **S** to save and **F** to finish. The profile is now in enforce mode in `/etc/apparmor.d/opt.shikumi.bin.shikumi-api`. If the session went wrong, install the reference profile instead (next step).

### Step 6: Compare with the reference profile, and add what aa-genprof cannot see.

```bash
R=~/shikumi-linux-labs/config/apparmor
P=/etc/apparmor.d/opt.shikumi.bin.shikumi-api
sudo diff "$R/opt.shikumi.bin.shikumi-api" "$P"
sudo ${EDITOR:-nano} "$P"
sudo apparmor_parser -r "$P"
```

The generated file is readable only by root, hence `sudo diff`. In the editor, make two changes that aa-genprof cannot suggest:

1. Change the line that opens the profile, `/opt/shikumi/bin/shikumi-api {`, to `/opt/shikumi/bin/shikumi-api flags=(attach_disconnected) {`. systemd's sandbox (Lab 5.3) gives the service its own mount view, so `/run/systemd/notify` and `/dev/null` lie outside it. AppArmor cannot name such "disconnected" paths and refuses them, even in complain mode, so the log never offers a rule.
2. Add these two rules inside the braces, so the service may send `READY=1` to systemd's socket:

```
  @{run}/systemd/notify w,
  unix (connect, send) type=dgram peer=(label=unconfined),
```

Instead of editing, you can install the reference profile, which has all of this:

```bash
sudo install -m 0644 "$R/opt.shikumi.bin.shikumi-api" \
  /etc/apparmor.d/
sudo apparmor_parser -r "$P"
```

### Step 7: Start the service and confirm it runs confined.

```bash
sudo systemctl start shikumi-api
ps -eZ | grep shikumi-api
curl -s 'http://127.0.0.1:8000/data?name=hello.txt'; echo
```

If `systemctl start` waits 15 seconds and fails with a timeout, the profile is blocking the `READY=1` message. `sudo journalctl -k -g 'apparmor="DENIED"' -n 3` names `/run/systemd/notify`, or says `disconnected path` if the `flags=` line is missing. Fix the profile as in step 6. Until then, systemd retries about every 16 seconds (the 15-second timeout plus `RestartSec=1`). That is too slow to reach the start limit, so it keeps going until you run `sudo systemctl stop shikumi-api`.

### Step 8: Ask for a file the profile does not allow.

```bash
sudo install -d -m 0755 /srv/shikumi-data
echo "outside the profile" | sudo tee /srv/shikumi-data/hello.txt
ls -l /srv/shikumi-data/hello.txt
sudo install -m 0644 data-dir.conf /etc/systemd/system/shikumi-api.service.d/data-dir.conf
sudo systemctl daemon-reload && sudo systemctl restart shikumi-api
curl -s 'http://127.0.0.1:8000/data?name=hello.txt'; echo
sudo journalctl -k -g 'apparmor="DENIED"' -n 3 --no-pager
```

The file is world-readable, yet the app gets `PermissionError`. Unix permissions (DAC) allow it; the AppArmor profile (MAC) does not. The kernel log names the profile, the path and the operation.

### Step 9: Put the data directory back.

```bash
sudo rm /etc/systemd/system/shikumi-api.service.d/data-dir.conf
sudo systemctl daemon-reload && sudo systemctl restart shikumi-api
sudo systemctl start shikumi-api@8001 shikumi-api@8002
```

> **Fedora / RHEL-family (alternate path, untested)**
>
> SELinux labels files and processes instead of matching paths. Serve a new directory with nginx and fix the denial properly:
>
> ```bash
> sudo mkdir -p /srv/site && echo hello | sudo tee /srv/site/index.html
> # point an nginx server block's root at /srv/site, reload nginx, then:
> curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1/   # 403 with correct permissions
> sudo ausearch -m avc -ts recent
> sudo semanage fcontext -a -t httpd_sys_content_t '/srv/site(/.*)?'
> sudo restorecon -Rv /srv/site
> ```
>
> `chcon -t httpd_sys_content_t` also fixes it, but only until the next `restorecon` or relabel. See `config/selinux/README.md`.

> **Debian**
>
> Same as Ubuntu.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 6.1
```

- The `/opt/shikumi/bin/shikumi-api` profile is loaded in enforce mode
- `shikumi-api.service` runs confined by it and `/data` returns 200
- The kernel log holds the step 8 `apparmor="DENIED"` line: the profile refusing `/srv/shikumi-data/hello.txt`
- The `data-dir.conf` drop-in is gone

## Stretch challenge

Find the abstractions your profile includes in `/etc/apparmor.d/abstractions/` and read `python`. Which paths does it allow that you never saw a prompt for?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/06.1-first-apparmor-profile/cleanup.sh
```

Removes the `data-dir.conf` drop-in, `/srv/shikumi-data` and `~/labs/6.1`. The profile stays loaded for Lab 6.2.

## Coreutils used

`ls`, `install`, `tee`, `cat`, `tr`, `sleep`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
