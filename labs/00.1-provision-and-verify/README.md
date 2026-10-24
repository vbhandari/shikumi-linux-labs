# Lab 0.1: Provision and verify your lab VM

**Module M00 · Orientation and the lab VM** · about 30 min · [Lab index](../../README.md#lab-index)

**Goal:** Create an Ubuntu 26.04 LTS VM, clone this repo into it, confirm it has everything the course needs, and save a clean snapshot.

## Before you start

- A laptop or desktop with 4 GB RAM and 20 GB disk to spare, and either [Multipass](https://canonical.com/multipass) or [Vagrant](https://developer.hashicorp.com/vagrant) with a provider (VirtualBox, VMware or Parallels).
- `git` on the host, to fetch the VM files.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/00.1-provision-and-verify/setup.sh
cd ~/labs/0.1
```

### Step 1: On the host, fetch the repo and create the VM with Multipass.

```bash
git clone https://github.com/vbhandari/shikumi-linux-labs.git
cd shikumi-linux-labs
./vm/multipass.sh
multipass shell shikumi
```

cloud-init installs the course packages and clones the repo to `~/shikumi-linux-labs` inside the VM. It takes a few minutes.

### Step 2: Or create it with Vagrant instead.

```bash
cd shikumi-linux-labs/vm
vagrant up
vagrant ssh
```

The default machine is `bento/ubuntu-26.04` with 2 vCPU and 4 GB RAM.

### Step 3: Inside the VM, check the environment.

```bash
cd ~/shikumi-linux-labs
./bin/shikumi-check env
```

Every line under *Required tools* should say PASS. If you built the VM by hand, run `sudo bash vm/provision.sh` first.

### Step 4: Try the five shell essentials you will use in every lab.

```bash
sudo -v; echo "exit status: $?"
./bin/shikumi-check env | grep -i coreutils
man unshare      # q to quit
journalctl -b | less   # q to quit
```

### Step 5: On the host, take a snapshot to return to later.

```bash
multipass stop shikumi && multipass snapshot shikumi --name clean && multipass start shikumi
# or, with Vagrant:
vagrant snapshot save clean
```

Take another snapshot before M06, M11 and M13, so a broken lab is one restore away.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Create the alternate machine with `vagrant up fedora` (box `bento/fedora-44`). `provision.sh` uses `dnf`, enables firewalld with SSH allowed and leaves SELinux enforcing. `shikumi-check env` then reports SELinux instead of AppArmor.

> **Debian**
>
> `vagrant up debian` (box `bento/debian-13`). Debian ships GNU coreutils and classic sudo, and has no user-namespace restriction.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 0.1
```

- Distro reads `Ubuntu 26.04 LTS` (or later 26.04.x) and PID 1 is `systemd`
- MAC reads `AppArmor enabled`; userns restrict reads `1`
- coreutils reads `uutils (Rust)` and sudo reads `sudo-rs (Rust)`
- Every required tool reports PASS and the script ends with `All checks passed.`

## Stretch challenge

Run `multipass info shikumi` (or `vagrant ssh-config`) and note the VM's IP address. You will use it from the host in Labs 1.3 and 11.1.

## Cleanup

```bash
~/shikumi-linux-labs/labs/00.1-provision-and-verify/cleanup.sh
```

Nothing to undo. Keep the VM and its `clean` snapshot.

## Coreutils used

`ls`, `cat`, `head`, `df`, `tr`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
