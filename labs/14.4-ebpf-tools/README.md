# Lab 14.4: eBPF: ready-made tools, then your own

**Module M14 · Observability and troubleshooting** · about 30 min · [Lab index](../../README.md#lab-index)

**Goal:** Use bcc's ready-made tools on disk and network activity, then finish two short bpftrace scripts: opens per process, and request latency from accept to close.

## Before you start

- Lab 14.3 done.
- nginx proxying to `@8001` and `@8002` (Lab 12.1).

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/openat_by_comm.bt`](files/openat_by_comm.bt)
- [`files/request_latency.bt`](files/request_latency.bt)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/14.4-ebpf-tools/setup.sh
cd ~/labs/14.4
```

### Step 1: Check the kernel supports it.

```bash
ls -l /sys/kernel/btf/vmlinux
sudo bpftrace --version
ls /usr/sbin/*-bpfcc | head
d=/usr/share/bpftrace/tools
if [ -d "$d" ]; then ls "$d" | head
else dpkg -L bpftrace | grep '\.bt$' | head; fi
```

eBPF runs small verified programs inside the kernel. It needs root, and BTF type information lets tools work across kernel versions.

### Step 2: Watch disk latency during a fio job.

```bash
fio --name=bio --filename=fio.dat --size=256M \
  --rw=randwrite --bs=4k --ioengine=psync --direct=1 \
  --runtime=20 --time_based --output=/dev/null &
sudo biolatency-bpfcc 5 2
wait; rm -f fio.dat
```

### Step 3: Watch nginx connect to its upstreams.

```bash
sudo timeout 10 tcpconnect-bpfcc &
sleep 2
for i in 1 2 3 4; do
  curl -s --cacert /etc/nginx/shikumi-tls/ca.crt \
    -o /dev/null https://localhost/healthz
done
wait
```

Since Lab 12.2, port 80 only redirects, so the requests go to HTTPS, and `--cacert` makes curl trust the lab CA from Lab 12.2. Each one shows nginx connecting to 127.0.0.1 port 8001 or 8002.

### Step 4: Try three more tools.

```bash
sudo timeout 10 execsnoop-bpfcc
sudo timeout 10 opensnoop-bpfcc -n shikumi-api
sudo timeout 10 tcplife-bpfcc
```

While each runs, use the VM in a second terminal: run commands, request `/data`, make requests.

### Step 5: Finish openat_by_comm.bt and run it.

```bash
${EDITOR:-nano} openat_by_comm.bt
sudo bpftrace openat_by_comm.bt
```

Count with `@opens[comm] = count();`. Press Ctrl-C after a couple of intervals.

### Step 6: Finish request_latency.bt and run it under load.

```bash
${EDITOR:-nano} request_latency.bt
sudo bpftrace request_latency.bt &
sleep 3
python3 ~/shikumi-linux-labs/app/loadgen.py \
  'http://127.0.0.1:8001/slow?ms=50' -c 5 -n 100
sudo pkill -INT bpftrace; wait
```

Store `nsecs` in `@start[pid, args.ret]`; on close, `hist()` the difference divided by 1000000, then `delete()` the entry. The histogram should cluster around 50 ms. The reference solutions are in `bpf/` at the top of the repo.

> **Fedora / RHEL-family (alternate path, untested)**
>
> bcc tools are in `/usr/share/bcc/tools/` without the `-bpfcc` suffix: `sudo /usr/share/bcc/tools/biolatency 5 2`.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 14.4
```

- Kernel BTF is present
- Your two `.bt` files have no `TODO` left and pass `bpftrace --dry-run`

## Stretch challenge

Extend `request_latency.bt` to also print a histogram per instance (`@request_ms[pid]`). Then compare with nginx's own view by adding `$upstream_response_time` to its access log format.

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/14.4-ebpf-tools/cleanup.sh
```

Stops any bpftrace left running and removes `~/labs/14.4`.

## Coreutils used

`ls`, `head`, `timeout`, `sleep`, `rm`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. request_latency.bt and openat_by_comm.bt pass bpftrace --dry-run, and request_latency.bt was run against the app on a Debian 13 host.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
