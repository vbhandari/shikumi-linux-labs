# Lab 11.3: Route and NAT out of a namespace

**Module M11 · Firewalls, network namespaces and fault injection** · about 25 min · [Lab index](../../README.md#lab-index)

**Goal:** Give `blue` a way out to the internet through the host: a second veth pair, IP forwarding for this boot, a masquerade rule, and a ufw route rule.

## Before you start

- Lab 11.2 done, with `blue` still in place.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/11.3-routing-and-nat/setup.sh
cd ~/labs/11.3
```

### Step 1: Turn on forwarding for this boot only.

```bash
sysctl -n net.ipv4.ip_forward > ip_forward.orig
sudo sysctl -w net.ipv4.ip_forward=1
```

Forwarding makes the VM a router. **On a public cloud VM** that is safe here only because ufw's forward policy stays DROP and step 4 allows just `veth-host` to the uplink. Never set ufw's forward policy to ACCEPT on a public host, and run the cleanup when you finish: it restores `ip_forward`.

### Step 2: Connect blue to the host.

```bash
sudo ip link add veth-host type veth peer name veth-blue-up
sudo ip link set veth-blue-up netns blue
sudo ip addr add 10.200.1.1/24 dev veth-host
sudo ip link set veth-host up
sudo ip -n blue addr add 10.200.1.2/24 dev veth-blue-up
sudo ip -n blue link set veth-blue-up up
sudo ip -n blue route add default via 10.200.1.1
sudo ip netns exec blue ping -c 2 10.200.1.1
```

### Step 3: Add masquerade, and try to get out.

```bash
cat ~/shikumi-linux-labs/config/nftables/nat.nft
sudo nft -f ~/shikumi-linux-labs/config/nftables/nat.nft
sudo ip netns exec blue \
  curl -s -m 5 -o /dev/null -w '%{http_code}\n' http://1.1.1.1
sudo ip netns exec blue ping -c 2 -W 2 1.1.1.1
```

curl prints `000` after 5 seconds: TCP still can't get out. ufw's default forward policy is DROP (`grep FORWARD /etc/default/ufw`), so the host refuses to route blue's connections. The ping gets through anyway: ufw's `before.rules` accept ICMP echo requests in FORWARD by default. That makes ping a poor test of a firewall, so this lab tests with TCP.

### Step 4: Allow forwarding from blue to the uplink only.

```bash
UPLINK=$(ip route show default | awk '{print $5; exit}')
sudo ufw route allow in on veth-host out on "$UPLINK"
sudo ip netns exec blue ping -c 3 1.1.1.1
sudo ip netns exec blue \
  curl -s -o /dev/null -w '%{http_code}\n' http://1.1.1.1/
```

Use IP addresses here: blue has no DNS yet. Its `/etc/resolv.conf` is the host's, which points at systemd-resolved's stub on 127.0.0.53, and blue's 127.0.0.53 is its own empty loopback.

### Step 5: Give blue its own resolver.

```bash
sudo ip netns exec blue getent hosts ubuntu.com || echo "no DNS in blue"
sudo mkdir -p /etc/netns/blue
echo "nameserver 1.1.1.1" | sudo tee /etc/netns/blue/resolv.conf
sudo ip netns exec blue getent hosts ubuntu.com
sudo ip netns exec blue curl -sI https://ubuntu.com | head -n 1
```

`ip netns exec` bind-mounts each file in `/etc/netns/blue/` over its `/etc` twin, for that command only.

### Step 6: Watch each hop.

```bash
sudo ip netns exec blue ping -c 20 -i 0.5 1.1.1.1 \
  >/dev/null & P=$!
sudo tcpdump -ni veth-host -c 2 icmp
sudo tcpdump -ni "$UPLINK" -c 2 icmp
wait $P
```

On `veth-host` the source is 10.200.1.2. On the uplink it is the VM's own address: masquerade rewrote it.

### Step 7: Trace one packet through the rules.

```bash
sudo nft add table inet shikumi_trace
sudo nft 'add chain inet shikumi_trace pre { type filter hook prerouting priority -350; }'
sudo nft add rule inet shikumi_trace pre ip saddr 10.200.1.2 icmp type echo-request meta nftrace set 1
sudo timeout 3 nft monitor trace | head -n 20 & M=$!
sleep 1
sudo ip netns exec blue ping -c 1 1.1.1.1 >/dev/null
wait $M
sudo nft delete table inet shikumi_trace
```

Start the monitor first: it shows only packets sent after it subscribes. The trace runs from prerouting into FORWARD and ends at `ufw-before-forward`'s ICMP accept, the rule that let step 3's ping through.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Put `veth-host` in firewalld's `trusted` zone and enable masquerade on the uplink's zone; skip the nft and ufw steps. See `config/firewalld/README.md`. *(to verify)*

> **Debian**
>
> Without ufw there is no forward DROP policy, so step 4 is not needed.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 11.3
```

- `blue` reaches `http://1.1.1.1/` over TCP (any HTTP status, not `000`)
- The `ip shikumi_nat` table and the ufw route rule are in place

## Stretch challenge

Remove the ufw route rule and use `nft monitor trace` to find exactly which chain drops the packet.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/11.3-routing-and-nat/cleanup.sh
```

Run after Lab 11.4. Deletes the NAT table, the ufw route rule, `veth-host`, any trace table and `/etc/netns/blue` (and `/etc/netns` itself if that leaves it empty), and restores `ip_forward`. The script also removes `~/labs/11.3`.

## Coreutils used

`cat`, `head`, `timeout`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
