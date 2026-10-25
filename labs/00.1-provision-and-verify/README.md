# Lab 0.1: Provision and verify your lab VM

**Module M00 · Orientation and the lab VM** · about 30 min · [Lab index](../../README.md#lab-index)

**Goal:** Create an Ubuntu 26.04 LTS VM, clone this repo into it, confirm it has everything the course needs, and save a clean snapshot.

## Before you start

- A laptop or desktop with 4 GB RAM and 20 GB disk to spare, and either [Multipass](https://canonical.com/multipass) or [Vagrant](https://developer.hashicorp.com/vagrant) with a provider (VirtualBox, VMware or Parallels).
- `git` on the host, to fetch the VM files.
- Or, instead of a local VM, any Ubuntu 26.04 cloud VM you can SSH into (Hetzner, AWS and so on): see **On a cloud VM** in step 5.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 1: On the host, check the prerequisites.

```bash
git --version
multipass version        # or: vagrant --version && vagrant plugin list
```

You need `git`, and either Multipass or Vagrant with a provider (VirtualBox, VMware or Parallels). The VM takes 2 vCPU, 4 GB RAM and 20 GB disk.

### Step 2: On the host, clone the repo.

```bash
git clone https://github.com/vbhandari/shikumi-linux-labs.git
cd shikumi-linux-labs
```

The host copy is only for creating the VM: it holds `vm/multipass.sh`, `vm/cloud-init.yaml` and `vm/Vagrantfile`.

### Step 3: On the host, create the VM with Multipass.

```bash
./vm/multipass.sh
```

This launches Ubuntu 26.04 as `shikumi` with `vm/cloud-init.yaml`, and waits until cloud-init has finished. cloud-init runs `vm/provision.sh`, which installs the course packages. It takes a few minutes.

### Step 4: Or create it with Vagrant instead.

```bash
cd vm
vagrant up
```

The default machine is `ubuntu` (box `bento/ubuntu-26.04`, 2 vCPU, 4 GB RAM). Vagrant runs `vm/provision.sh` as its provisioner. Run every later `vagrant` command from this `vm/` folder.

### Step 5: Get into the VM.

```bash
multipass shell shikumi
# or, with Vagrant:
vagrant ssh
```

From here on, every command runs inside the VM unless a step says *on the host*.

**On a cloud VM** (Hetzner, AWS and so on), skip steps 1 to 5. Create an Ubuntu 26.04 VM with your SSH key in the provider's console, log in with `ssh USER@VM_IP`, and provision it yourself:

```bash
sudo apt-get install -y git      # if git is missing
git clone https://github.com/vbhandari/shikumi-linux-labs.git
sudo bash ~/shikumi-linux-labs/vm/provision.sh
```

Then log out and back in, so new group memberships apply, and go on with step 6. `USER@VM_IP` stands for your login and the server's public address; later labs use the same placeholder.

### Step 6: Inside the VM, make sure the repo is there.

```bash
cd ~
[ -d ~/shikumi-linux-labs/.git ] || git clone https://github.com/vbhandari/shikumi-linux-labs.git ~/shikumi-linux-labs
git -C ~/shikumi-linux-labs log -1 --oneline
```

The VM has its own clone in your home directory, `~/shikumi-linux-labs`: cloud-init (Multipass) or `provision.sh --clone vagrant` (Vagrant) cloned it from GitHub during provisioning. Nothing is shared with the host's copy: Multipass mounts nothing and the Vagrant synced folder is turned off. The second line clones it now if provisioning could not. To update later, run `git -C ~/shikumi-linux-labs pull` inside the VM.

### Step 7: Run the lab setup and the environment check.

```bash
~/shikumi-linux-labs/labs/00.1-provision-and-verify/setup.sh
cd ~/shikumi-linux-labs
./bin/shikumi-check env
```

Every line under *Required tools* should say PASS. If any is missing, provisioning did not finish: run `sudo bash vm/provision.sh`, then check again. From Lab 1.1 on, every lab starts the same way, with its `setup.sh` as step 0.

### Step 8: Try the five shell essentials you will use in every lab.

```bash
sudo true; echo "exit status: $?"
./bin/shikumi-check env | grep -i coreutils
man unshare      # q to quit
journalctl -b | less   # q to quit
```

`sudo true` should print `exit status: 0`. Use it, not `sudo -v`, to test sudo: with sudo-rs, `sudo -v` fails for accounts that use NOPASSWD rules and have no password, which is how Multipass and most cloud images set up their user. `journalctl -b` shows the whole system's log only to members of `adm` or `systemd-journal`. `provision.sh` adds you to both; if you see only your own messages, log out and back in.

### Step 9: Leave the VM and, on the host, take the clean snapshot.

```bash
exit
multipass stop shikumi && multipass snapshot shikumi --name clean && multipass start shikumi
# or, with Vagrant (from vm/):
vagrant snapshot save ubuntu clean
```

Take more snapshots the same way before M06, M11 and M13, named `pre-m06`, `pre-m11` and `pre-m13`, so a broken lab is one restore away: `multipass restore shikumi.clean` or `vagrant snapshot restore ubuntu clean`. Lab 15.1 starts from `clean` and saves `stack`. On a cloud VM, take the snapshots in the provider's console instead.

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

Run `multipass info shikumi` (or `vagrant ssh-config`) and note the VM's IP address; on a cloud VM it is the address you SSH to. Later labs write it as `VM_IP`, Lab 9.1 saves it in `~/labs/9.1/vm-ip.txt`, and Labs 1.3 and 11.1 use it from the host.

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
