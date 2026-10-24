# Lab 11.4: Inject delay and loss with tc netem

**Module M11 · Firewalls, network namespaces and fault injection** · about 25 min · [Lab index](../../README.md#lab-index)

**Goal:** Add 100 ms of delay and 5 % loss between `red` and `blue`, watch latencies and retries in the load generator, watch TCP's window grow under delay, and remove the fault.

## Before you start

- Lab 11.2 done, with the app running in `blue` on 10.200.0.1:8020.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/11.4-netem-faults/setup.sh
cd ~/labs/11.4
```

### Step 1: Measure a baseline from red.

```bash
sudo ip netns exec red python3 ~/shikumi-linux-labs/app/loadgen.py http://10.200.0.1:8020/healthz \
  -c 5 -n 100 --timeout 1 --retries 2 | tee before.txt
```

### Step 2: Add delay and loss on blue's side of the link.

```bash
sudo ip netns exec blue tc qdisc add dev veth-blue root netem delay 100ms loss 5%
sudo ip netns exec blue tc qdisc show dev veth-blue
sudo ip netns exec red ping -c 5 10.200.0.1
```

netem acts on packets leaving `veth-blue`, so every round trip gains 100 ms.

### Step 3: Measure again.

```bash
sudo ip netns exec red python3 ~/shikumi-linux-labs/app/loadgen.py http://10.200.0.1:8020/healthz \
  -c 5 -n 100 --timeout 1 --retries 2 | tee netem.txt
```

p50 rises by about 100 ms. A lost SYN is resent after one second, longer than the client's timeout, so some requests need a retry. This is how timeouts and retry storms are reproduced before production finds them.

### Step 4: Watch the congestion window grow under delay.

```bash
sudo ip netns exec blue tc qdisc change dev veth-blue root netem delay 100ms
sudo ip netns exec blue iperf3 -s -1 -D
sudo ip netns exec red iperf3 -c 10.200.0.1 -t 15 > iperf-delay.txt &
for i in 1 2 3; do sleep 4; sudo ip netns exec red ss -tmi dst 10.200.0.1 | grep -o 'cwnd:[0-9]*\|rtt:[0-9.]*'; done
wait; tail -n 4 iperf-delay.txt
```

With 100 ms RTT, throughput is limited by how much data may be in flight: the window and the buffers from Lab 10.4.

### Step 5: Try other faults, then remove the qdisc.

```bash
sudo ip netns exec blue tc qdisc change dev veth-blue root netem delay 50ms 20ms
sudo ip netns exec red ping -c 5 10.200.0.1
sudo ip netns exec blue tc qdisc change dev veth-blue root netem delay 10ms reorder 25% 50%
sudo ip netns exec blue tc qdisc del dev veth-blue root
sudo ip netns exec blue tc qdisc show dev veth-blue
```

> **Fedora / RHEL-family (alternate path, untested)**
>
> Fedora may need `sudo dnf install kernel-modules-extra` for `sch_netem`. *(to verify)*

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 11.4
```

- `before.txt` and `netem.txt` hold results, and p50 in `netem.txt` is at least 90 ms higher
- No netem qdisc is left on `veth-blue`

## Stretch challenge

Add `--retries 0` and find the loss rate at which more than 10 % of requests fail. Then add 1 s of jitter and explain the p99.

## Cleanup

```bash
~/shikumi-linux-labs/labs/11.4-netem-faults/cleanup.sh
```

Removes any netem qdisc and stops iperf3. Then run the cleanups of Labs 11.3 and 11.2, in that order.

## Coreutils used

`tee`, `tail`, `cut`, `sleep`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
