# Lab 10.4: Socket buffers and autotuning

**Module M10 · TCP for backend and test engineers** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** Watch TCP's buffers grow during an `iperf3` run, lower the receive buffer limit for this boot only, and compare.

## Before you start

- Lab 10.3 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/10.4-buffers-and-autotuning/setup.sh
cd ~/labs/10.4
```

### Step 1: Read the buffer settings.

```bash
sysctl net.ipv4.tcp_rmem net.ipv4.tcp_wmem net.ipv4.tcp_moderate_rcvbuf
```

Each is min, default and max in bytes. With `tcp_moderate_rcvbuf=1` the kernel grows a socket's receive buffer towards the max as needed.

### Step 2: Run iperf3 on loopback and watch the socket.

```bash
iperf3 -s -p 5201 & S=$!
sleep 1
iperf3 -c 127.0.0.1 -p 5201 -t 10 | tee default.txt & C=$!
sleep 4; ss -tmi '( dport = :5201 )' | head -n 8
wait $C
```

`skmem:(r...,rb...)` shows the receive buffer in use and its size, `rcv_space` what autotuning chose, `cwnd` the congestion window, `rtt` the round-trip time.

### Step 3: Lower the maximum for this boot only, and compare.

```bash
sysctl -n net.ipv4.tcp_rmem > tcp_rmem.orig
sudo sysctl -w net.ipv4.tcp_rmem="4096 131072 262144"
iperf3 -c 127.0.0.1 -p 5201 -t 10 | tee small.txt
sudo sysctl -w net.ipv4.tcp_rmem="$(cat tcp_rmem.orig)"
grep receiver default.txt small.txt
```

On loopback the round-trip time is tiny, so even a small buffer covers the bandwidth-delay product and the difference may be small. Lab 11.4 adds 100 ms of delay, where buffer size matters.

### Step 4: Set the buffer by hand and see autotuning stop.

```bash
iperf3 -c 127.0.0.1 -p 5201 -t 5 -w 64K | tail -n 4
kill $S
```

`-w` sets `SO_RCVBUF`, which turns autotuning off for that socket.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 10.4
```

- `net.ipv4.tcp_rmem` is back to the value in `tcp_rmem.orig`
- `default.txt` and `small.txt` hold iperf3 results

## Stretch challenge

Compute the bandwidth-delay product for 1 Gbit/s at 100 ms RTT. Is the default `tcp_rmem` max large enough? Test your answer in Lab 11.4.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/10.4-buffers-and-autotuning/cleanup.sh
```

Restores `tcp_rmem` if a saved value exists, and stops iperf3.

## Coreutils used

`tee`, `cat`, `head`, `tail`, `sleep`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): steps and checks pass; the sysctl write was skipped.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
