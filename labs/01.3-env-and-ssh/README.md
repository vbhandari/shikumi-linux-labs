# Lab 1.3: Configure the app from the environment and reach it over SSH

**Module M01 · Shell fluency** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Run the sample app with settings taken from environment variables, then open it from your host's browser through an SSH tunnel.

## Before you start

- Lab 1.2 done.
- An SSH client on the host (built into macOS, Linux and Windows 10 or later), and `rsync` on the host for step 5 (or use `scp`, which comes with SSH).

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/app.env`](files/app.env)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/01.3-env-and-ssh/setup.sh
cd ~/labs/1.3
```

### Step 1: See how a variable reaches a child process only when exported.

```bash
SHIKUMI_PORT=9999
python3 -c 'import os; print(os.environ.get("SHIKUMI_PORT"))'
export SHIKUMI_PORT
python3 -c 'import os; print(os.environ.get("SHIKUMI_PORT"))'
unset SHIKUMI_PORT
```

### Step 2: Load the settings and start the app in the foreground.

```bash
source app.env
env | grep SHIKUMI
python3 ~/shikumi-linux-labs/app/shikumi_api.py
```

It prints `shikumi-api pid=NNNN listening on 127.0.0.1:8080`. Leave it running. Because it listens on 127.0.0.1, nothing outside the VM can reach it directly.

### Step 3: On the host, make sure the VM accepts your SSH key.

```bash
# Multipass (the VM only knows Multipass's own key at first):
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''    # skip if you already have a key
multipass exec shikumi -- bash -c "echo '$(cat ~/.ssh/id_ed25519.pub)' >> ~/.ssh/authorized_keys"
multipass info shikumi | grep IPv4
```

Vagrant already set up a key for you, and on a cloud VM you already log in with your key: skip this step.

### Step 4: On the host, open a tunnel from your port 8080 to the VM's 127.0.0.1:8080.

```bash
ssh -N -L 8080:127.0.0.1:8080 USER@VM_IP
# or, with Vagrant:
vagrant ssh -- -N -L 8080:127.0.0.1:8080
```

`USER@VM_IP` is a placeholder for your VM login: with Multipass, `ubuntu@` and the address from step 3; on a cloud VM, your own user and the server's public address. Then open <http://localhost:8080/healthz> in the host's browser. The request travels inside SSH to the VM, where it arrives from 127.0.0.1.

### Step 5: Copy a file from the VM to the host with rsync.

```bash
# inside the VM:
echo "made on $(hostname)" > ~/labs/1.3/from-vm.txt
# on the host:
rsync -av USER@VM_IP:labs/1.3/from-vm.txt .
scp USER@VM_IP:labs/1.3/from-vm.txt .   # same, without rsync
```

rsync must be installed on both ends. `provision.sh` installs it in the VM; if the host has none (Windows, some minimal installs), use the `scp` line. With Vagrant, `vagrant ssh-config` shows the user, address, port and key to use.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 1.3
```

- `curl http://127.0.0.1:8080/healthz` inside the VM returns HTTP 200
- The running app's environment contains `SHIKUMI_PORT=8080`
- The host browser shows `{"status": "ok", ...}` through the tunnel (not checked by the script)

## Stretch challenge

Put the `export` lines in `~/.bashrc`, open a new SSH session and confirm `env | grep SHIKUMI` shows them. Then remove them again: later labs set these values in a systemd unit instead.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/01.3-env-and-ssh/cleanup.sh
```

Stops any `shikumi_api.py` you started on port 8080 and removes `~/labs/1.3`. Close the SSH tunnel on the host with Ctrl-C.

## Coreutils used

`env`, `cat`, `tr`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): setup, steps and checks pass.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
