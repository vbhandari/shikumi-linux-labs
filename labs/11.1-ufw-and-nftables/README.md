# Lab 11.1: ufw, and the nftables underneath

**Module M11 · Firewalls, network namespaces and fault injection** · about 30 min · [Lab index](../../README.md#lab-index)

**Goal:** Enable ufw without locking yourself out, open a port, find ufw's rules in nftables, and show that a drop in your own nft table wins over a ufw allow.

## Before you start

- Lab 10.4 done.
- The VM address from Lab 9.1 (`~/labs/9.1/vm-ip.txt`).
- Take a VM snapshot first.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/11.1-ufw-and-nftables/setup.sh
cd ~/labs/11.1
```

### Step 1: Safety first: arm an automatic undo, and allow SSH before enabling anything.

```bash
sudo systemd-run --on-active=10min --unit shikumi-ufw-revert /usr/sbin/ufw disable
systemctl list-timers shikumi-ufw-revert.timer --no-pager
sudo ufw app list
sudo ufw allow OpenSSH
sudo ufw --force enable
sudo ufw status verbose
```

Multipass and Vagrant both reach the VM over SSH on port 22. Open a **new** SSH session from the host now. If it works, cancel the undo:

```bash
sudo systemctl stop shikumi-ufw-revert.timer
```

If it does not, wait: ufw disables itself within 10 minutes. `systemd-run --unit shikumi-ufw-revert` creates two transient units, `shikumi-ufw-revert.timer` and `shikumi-ufw-revert.service`; step 5 arms `shikumi-nft-revert` the same way.

### Step 2: Run the app on two ports, reachable from outside the VM.

```bash
python3 ~/shikumi-linux-labs/app/shikumi_api.py --host 0.0.0.0 --port 8010 &
python3 ~/shikumi-linux-labs/app/shikumi_api.py --host 0.0.0.0 --port 8011 &
```

On the host, `curl -m 3 http://VM_IP:8010/healthz` times out: ufw's default policy denies incoming connections.

### Step 3: Allow both ports.

```bash
sudo ufw allow 8010/tcp
sudo ufw allow 8011/tcp
sudo ufw status numbered
```

From the host, both ports now answer.

### Step 4: Find ufw's chains in nftables.

```bash
sudo nft list tables
sudo nft list chain ip filter ufw-user-input
```

Ubuntu's ufw drives iptables through its nftables backend, so its rules are ordinary nft chains.

### Step 5: Add your own table that drops 8011, with its own undo.

```bash
cat ~/shikumi-linux-labs/config/nftables/shikumi.nft
sudo systemd-run --on-active=5min --unit shikumi-nft-revert /usr/sbin/nft delete table inet shikumi
sudo nft -f ~/shikumi-linux-labs/config/nftables/shikumi.nft
sudo nft list table inet shikumi
```

From the host, 8010 still answers and 8011 times out, although ufw allows it. A packet must pass the base chain of every table on the hook; an accept in one table does not override a drop in another. The counter in the `shikumi` table shows each dropped SYN.

> **Fedora / RHEL-family (alternate path, untested)**
>
> firewalld manages zones instead of a single rule list:
>
> ```bash
> sudo firewall-cmd --get-active-zones
> sudo firewall-cmd --add-port=8010/tcp             # runtime only
> sudo firewall-cmd --reload                        # the undo: drops runtime changes
> sudo firewall-cmd --permanent --add-port=8010/tcp && sudo firewall-cmd --reload
> ```
>
> The raw `inet shikumi` table works the same way next to firewalld's own table.

> **Debian**
>
> Debian has no ufw by default. Do steps 4 and 5 with raw nft, or `sudo apt install ufw` and follow the Ubuntu steps.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 11.1
```

- ufw is active and allows OpenSSH, 8010/tcp and 8011/tcp
- The ufw undo timer is no longer pending
- ufw's chains appear in `nft list ruleset`
- The `inet shikumi` table is loaded and drops 8011 (load it again if its 5-minute undo already fired)

## Stretch challenge

Use `sudo ufw deny from VM_HOST_IP to any port 8010` (find the host's address in `sudo journalctl -k -g UFW` or `ss -tn`), and read where ufw put the rule in `ufw-user-input`.

## Cleanup

```bash
~/shikumi-linux-labs/labs/11.1-ufw-and-nftables/cleanup.sh
```

Deletes the `shikumi` table, the two port rules and both undo timers, and stops the two apps. ufw stays enabled with OpenSSH allowed.

## Coreutils used

`cat`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
