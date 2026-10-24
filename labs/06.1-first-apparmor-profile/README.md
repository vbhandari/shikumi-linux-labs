# Lab 6.1: Generate an AppArmor profile for the app

**Module M06 · Mandatory access control: AppArmor (core) · SELinux (alternate)** · about 30 min · [Lab index](../../README.md#lab-index)

**Goal:** Build an AppArmor profile for `/opt/shikumi/bin/shikumi-api` with `aa-genprof`, enforce it, and watch it refuse a file that Unix permissions allow.

## Before you start

- Lab 5.4 done.
- Take a VM snapshot first (`multipass snapshot` or `vagrant snapshot save`).

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

### Step 4: In a second terminal, run the app by its path and exercise it.

```bash
sudo -u shikumi /opt/shikumi/bin/shikumi-api --port 8600 &
sleep 1
curl -s http://127.0.0.1:8600/healthz; echo
curl -s 'http://127.0.0.1:8600/data?name=hello.txt'; echo
curl -s 'http://127.0.0.1:8600/files?n=3'; echo
sudo pkill -f 'shikumi-api --port 8600'
```

### Step 5: Back in aa-genprof, press S to scan, then answer the prompts.

- `/usr/bin/python3.14`: choose **(I)nherit**, so Python runs under the same profile (`ix`).
- Read access to `/opt/shikumi/bin/shikumi-api`: **(A)llow**.
- Abstractions such as `python` and `nameservice`: allow them.
- `/var/lib/shikumi/hello.txt`: choose **(G)lob** until it reads `/var/lib/shikumi/*`, then allow.
- Network `inet stream`: allow.

Press **S** to save and **F** to finish. The profile is now in enforce mode in `/etc/apparmor.d/opt.shikumi.bin.shikumi-api`. If the session went wrong, install the reference profile instead (next step).

### Step 6: Compare with the reference profile, or use it.

```bash
diff ~/shikumi-linux-labs/config/apparmor/opt.shikumi.bin.shikumi-api /etc/apparmor.d/opt.shikumi.bin.shikumi-api
# only if your profile does not work:
sudo install -m 0644 ~/shikumi-linux-labs/config/apparmor/opt.shikumi.bin.shikumi-api /etc/apparmor.d/
sudo apparmor_parser -r /etc/apparmor.d/opt.shikumi.bin.shikumi-api
```

### Step 7: Start the service and confirm it runs confined.

```bash
sudo systemctl start shikumi-api
ps -eZ | grep shikumi-api
curl -s 'http://127.0.0.1:8000/data?name=hello.txt'; echo
```

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
- The kernel log holds an `apparmor="DENIED"` line for the profile (from step 8)
- The `data-dir.conf` drop-in is gone

## Stretch challenge

Find the abstractions your profile includes in `/etc/apparmor.d/abstractions/` and read `python`. Which paths does it allow that you never saw a prompt for?

## Cleanup

```bash
~/shikumi-linux-labs/labs/06.1-first-apparmor-profile/cleanup.sh
```

Removes the `data-dir.conf` drop-in and `/srv/shikumi-data`. The profile stays loaded for Lab 6.2.

## Coreutils used

`ls`, `install`, `tee`, `cat`, `tr`, `sleep`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
