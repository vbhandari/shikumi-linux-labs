# Lab 9.3: Capture one request and label every packet

**Module M09 · Networking fundamentals** · about 20 min · [Lab index](../../README.md#lab-index)

**Goal:** See which process owns which port, time a request with `curl -w`, and capture it with tcpdump, from handshake to teardown.

## Before you start

- Lab 9.2 done.
- `shikumi-api@8001` running (Lab 5.4).

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/09.3-sockets-and-ports/setup.sh
cd ~/labs/9.3
```

### Step 1: List listening sockets, with and without sudo.

```bash
ss -tln
ss -tlnp
sudo ss -tlnp
```

`-p` shows process names only for your own processes unless you use `sudo`.

### Step 2: Time a request.

```bash
curl -s -o /dev/null -w 'connect %{time_connect}s  first byte %{time_starttransfer}s  total %{time_total}s\n' http://127.0.0.1:8001/healthz
curl -v http://127.0.0.1:8001/healthz
```

### Step 3: Capture one request on loopback.

```bash
sudo timeout 10 tcpdump -i lo -nn -l port 8001 | tee capture.txt & sleep 2
curl -s http://127.0.0.1:8001/healthz; echo
wait
```

`-l` makes tcpdump flush each line, so `tee` writes it straight away. The course avoids `-w file.pcap` here because Ubuntu's AppArmor profile for tcpdump limits where it may write.

### Step 4: Label the packets.

```bash
cat capture.txt
```

`[S]` SYN, `[S.]` SYN-ACK and `[.]` ACK are the handshake. `[P.]` carries the request and the response. The app closes first: `[F.]` from port 8001, then the client's `[F.]` and a final ACK. Write each packet's label into `labels.txt`.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 9.3
```

- `capture.txt` shows the handshake (`[S]`, `[S.]`), data (`[P.]`) and teardown (`[F.]`)

## Stretch challenge

Capture the same request through nginx in Lab 12.1 with `-i lo port 80 or port 8001`. How many TCP connections does one client request make?

## Cleanup

```bash
~/shikumi-linux-labs/labs/09.3-sockets-and-ports/cleanup.sh
```

Removes `~/labs/9.3`.

## Coreutils used

`timeout`, `tee`, `cat`, `sleep`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
