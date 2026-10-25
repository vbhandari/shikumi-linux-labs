# Lab 14.4: eBPF: ready-made tools, then your own

**Module M14 · Observability and troubleshooting** · about 30 min · [Lab index](../../README.md#lab-index)

**Goal:** Use bpftrace's ready-made tools on disk and network activity, then finish two short bpftrace scripts: opens per process, and request latency from accept to close.

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
dpkg -L bpftrace | grep '\.bt$' | head
```

eBPF runs small verified programs inside the kernel. It needs root, and BTF type information lets tools work across kernel versions. Ubuntu's `bpftrace` package ships about 40 ready-made tools as `/usr/sbin/*.bt`, such as `biolatency.bt`, `tcpconnect.bt` and `execsnoop.bt`; `sudo` finds them on its path. This lab uses them rather than bcc's `*-bpfcc` tools (package `bpfcc-tools`): those compile their programs at run time against the kernel headers, and most of them fail to build on Ubuntu 26.04's kernel 7.0. The `.bt` tools need only BTF.

### Step 2: Watch disk latency during a fio job.

```bash
fio --name=bio --filename=fio.dat --size=256M \
  --rw=randwrite --bs=4k --ioengine=psync --direct=1 \
  --runtime=20 --time_based --output=/dev/null & F=$!
sleep 1
sudo timeout -s INT 10 biolatency.bt
wait $F; rm -f fio.dat
```

`biolatency.bt` runs until Ctrl-C; `timeout -s INT 10` sends that Ctrl-C after 10 seconds. Then it prints one histogram of block I/O latency in microseconds, `@usecs`: with `--direct=1` most 4 KiB writes land in a few buckets, tens to hundreds of microseconds on a cloud SSD. bpftrace may first print `WARNING` lines about the tool's own code; they are harmless.

### Step 3: Watch nginx connect to its upstreams.

```bash
sudo timeout -s INT 10 tcpconnect.bt & T=$!
sleep 2
for i in 1 2 3 4; do
  curl -s --cacert /etc/nginx/shikumi-tls/ca.crt \
    -o /dev/null https://localhost/healthz
done
wait $T
```

Since Lab 12.2, port 80 only redirects, so the requests go to HTTPS, and `--cacert` makes curl trust the lab CA from Lab 12.2. Each request shows two lines: `curl` connecting to `::1` port 443 (`localhost` resolves to IPv6 first), and `nginx` connecting to 127.0.0.1 port 8001 or 8002. The columns are TIME, PID, COMM, then source and destination address and port.

### Step 4: Try three more tools.

```bash
sudo timeout -s INT 10 execsnoop.bt
sudo timeout -s INT 10 opensnoop.bt > opens.txt
grep -E 'PID|shikumi' opens.txt; rm -f opens.txt
sudo timeout -s INT 10 tcplife.bt
```

While each runs, use the VM in a second terminal: run commands, request `/data` (`curl -s 'http://127.0.0.1:8001/data?name=hello.txt'`), make requests.

- `execsnoop.bt` prints one line per `exec()`: time, PID, parent PID and the arguments.
- `opensnoop.bt` prints every `open()` on the system, so it goes to a file first. The `grep` keeps the header and the app's lines: `shikumi-api` opening `hello.txt` for `/data`. (Piped straight into `grep`, `timeout` would stop `grep` too at an interactive prompt, before it prints.)
- `tcplife.bt` prints one line per TCP connection when it closes: PID, process, addresses, ports, KB sent and received, and how long it lived in ms.

On Ubuntu, `sudo apt install libbpf-tools` adds prebuilt versions of the bcc tools (`biolatency-libbpf`, `tcpconnect-libbpf` and so on) that also work on kernel 7.0. This lab does not need them.

### Step 5: Finish openat_by_comm.bt and run it.

```bash
${EDITOR:-nano} openat_by_comm.bt
sudo bpftrace openat_by_comm.bt
```

Count with `@opens[comm] = count();`. Press Ctrl-C after a couple of intervals.

### Step 6: Finish request_latency.bt and run it under load.

```bash
${EDITOR:-nano} request_latency.bt
sudo bpftrace request_latency.bt & B=$!
sleep 3
python3 ~/shikumi-linux-labs/app/loadgen.py \
  'http://127.0.0.1:8001/slow?ms=50' -c 5 -n 100
sudo pkill -INT bpftrace; wait $B
```

Store `nsecs` in `@start[pid, args.ret]`. On close, read it back as `@start[pid, (int64)args.fd]`, the key the template's predicate already uses: `hist()` the difference divided by 1000000, then `delete()` the entry with the same key. The cast matters. `args.ret` is a signed `long` and `args.fd` an `unsigned int`, and bpftrace 0.25 refuses a map key whose types differ: `Argument mismatch for @start`. bpftrace may warn `Return value discarded` for the `delete()`; that is harmless. The histogram should cluster around 50 ms. The reference solutions are in `bpf/` at the top of the repo.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Fedora installs bpftrace's tools in `/usr/share/bpftrace/tools/`: `sudo timeout -s INT 10 bpftrace /usr/share/bpftrace/tools/biolatency.bt`. bcc's tools are in `/usr/share/bcc/tools/` without the `-bpfcc` suffix (`sudo /usr/share/bcc/tools/biolatency 5 2`). *(to verify)*

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

Run on an Ubuntu 26.04 VM (kernel 7.0, bpftrace 0.25): bcc's `-bpfcc` tools failed to build, and `request_latency.bt` failed bpftrace's type check. The lab now uses bpftrace's `.bt` tools, and the script casts `args.fd`; with the cast the check passed on that VM. The new tool steps are still to re-test.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
