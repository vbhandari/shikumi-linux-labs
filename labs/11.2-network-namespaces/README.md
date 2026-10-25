# Lab 11.2: Two network namespaces and a veth pair

**Module M11 · Firewalls, network namespaces and fault injection** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Create `blue` and `red` network namespaces, connect them with a veth pair, and run the app in `blue` where only `red` can reach it.

## Before you start

- Lab 11.1 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/11.2-network-namespaces/setup.sh
cd ~/labs/11.2
```

### Step 1: Create two namespaces.

```bash
sudo ip netns add blue
sudo ip netns add red
ip netns list
sudo ip -n blue -br link
```

A new network namespace has only a loopback interface, and it is down.

### Step 2: Connect them with a veth pair.

```bash
sudo ip link add veth-blue type veth peer name veth-red
sudo ip link set veth-blue netns blue
sudo ip link set veth-red netns red
sudo ip -n blue addr add 10.200.0.1/24 dev veth-blue
sudo ip -n red addr add 10.200.0.2/24 dev veth-red
for ns in blue red; do sudo ip -n $ns link set lo up; done
sudo ip -n blue link set veth-blue up
sudo ip -n red link set veth-red up
sudo ip -n blue -br a
```

### Step 3: Ping across, and see that the host cannot.

```bash
sudo ip netns exec red ping -c 3 10.200.0.1
ip -br link | grep veth || echo "no veth on the host"
ping -c 1 -W 1 10.200.0.1 || echo "the host has no route to 10.200.0.0/24"
```

`ip netns exec` runs a command inside the namespace; it does not trace or observe anything. Each namespace has its own interfaces, routes and firewall.

### Step 4: Run the app in blue and call it from red.

```bash
sudo ip netns exec blue sudo -u "$USER" python3 ~/shikumi-linux-labs/app/shikumi_api.py --host 10.200.0.1 --port 8020 &
sleep 1
sudo ip netns exec red curl -s http://10.200.0.1:8020/healthz; echo
sudo ip netns exec blue ss -tln
```

Leave the app running for Labs 11.3 and 11.4.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 11.2
```

- Namespaces `blue` and `red` exist with 10.200.0.1 and 10.200.0.2
- `red` can ping `blue`, and `/healthz` on 10.200.0.1:8020 returns 200 from `red`

## Stretch challenge

Look at blue's nftables ruleset (`sudo ip netns exec blue nft list ruleset`). Why is it empty, when the host has ufw enabled?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/11.2-network-namespaces/cleanup.sh
```

Run this cleanup only after Labs 11.3 and 11.4, which use the namespaces. It stops the app in `blue` and deletes both namespaces, which removes the veth pair too.

## Coreutils used

`sleep`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
