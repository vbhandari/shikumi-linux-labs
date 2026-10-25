# Lab 9.1: Map the VM's network

**Module M09 · Networking fundamentals** · about 15 min · [Lab index](../../README.md#lab-index)

**Goal:** List the VM's interfaces, addresses, routes and neighbours, see how netplan configures them, and record the address the host uses to reach the VM.

## Before you start

- Lab 0.1 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/09.1-interfaces-and-routes/setup.sh
cd ~/labs/9.1
```

### Step 1: List interfaces and addresses.

```bash
ip -br link
ip -br a
ip -d link show dev "$(ip route show default | awk '{print $5; exit}')" | head -n 2
```

`lo` is loopback. The uplink is usually `ens3`, `enp0s1` or `eth0`. `mtu 1500` is the largest packet the link carries.

### Step 2: Read the routing table and the neighbour cache.

```bash
ip r
ip route get 1.1.1.1
ip neigh
```

### Step 3: See how Ubuntu configures the network.

```bash
ls /etc/netplan
sudo netplan get
networkctl list --no-pager
networkctl status --no-pager | head -n 15
```

netplan's YAML is rendered into systemd-networkd configuration at boot.

### Step 4: Record the address the host can reach, and test it from the host.

```bash
ip -4 -br a show scope global
echo "VM_IP" > vm-ip.txt   # type the address, not VM_IP
# on the host (Multipass only: show the address):
multipass info shikumi | grep IPv4
ping -c 2 VM_IP
```

`VM_IP` is a placeholder: type the address itself. With Multipass, it is the address `multipass info` shows. With Vagrant, use the address on the second interface (the `private_network`); the first is NAT and the host cannot reach it. On a cloud VM, it is the public address you SSH to, if `ip a` shows it on the uplink (Hetzner does). Some providers (AWS, GCP) map the public address to a private one that `ip a` shows instead: write the private one into `vm-ip.txt`, because the check looks for an address on the VM, and use the public one from the host. Many cloud firewalls drop ping; if it fails, `ssh USER@VM_IP true` tests the path instead.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Fedora uses NetworkManager: `nmcli device status`, `nmcli connection show`, and profiles in `/etc/NetworkManager/system-connections/`.

> **Debian**
>
> Debian cloud images use ifupdown or systemd-networkd, depending on the image; there is no netplan.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 9.1
```

- The VM has a default route
- `vm-ip.txt` holds an address that is assigned to this VM

## Stretch challenge

Lower the uplink MTU to 1400 for this boot only (`sudo ip link set dev UPLINK mtu 1400`), check `ip -d link`, and set it back. What breaks if two ends of a path disagree on MTU?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/09.1-interfaces-and-routes/cleanup.sh
```

Nothing to undo. Keep `vm-ip.txt`: Lab 11.1 uses the address.

## Coreutils used

`ls`, `head`, `tr`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
