# Lab 14.3: Find the hot function with perf

**Module M14 · Observability and troubleshooting** · about 30 min · [Lab index](../../README.md#lab-index)

**Goal:** Profile the app under load with `perf`, see Python function names with `-X perf`, draw a flame graph, fix the hot function and compare.

## Before you start

- Lab 14.2 done.
- `perf` installed for the running kernel (`perf --version`).

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/14.3-perf-and-flame-graphs/setup.sh
cd ~/labs/14.3
```

### Step 1: Check what perf may see.

```bash
perf --version
sysctl kernel.perf_event_paranoid kernel.kptr_restrict
sudo perf stat -e cycles true 2>&1 | tail -n 4
sudo perf stat -e cpu-clock,context-switches sleep 1 2>&1 | tail -n 6
```

VMs often hide hardware counters, so `cycles` shows `<not supported>`. The software event `cpu-clock` always works. `sudo` is needed because of `perf_event_paranoid` and `kptr_restrict`.

### Step 2: Start the app and load its checksum endpoint.

```bash
python3 ~/shikumi-linux-labs/app/shikumi_api.py --port 8500 & APP=$!
sleep 1
python3 ~/shikumi-linux-labs/app/loadgen.py 'http://127.0.0.1:8500/checksum?kb=256' -c 4 -n 400 | tee slow.txt &
```

### Step 3: Record 20 seconds of stacks.

```bash
sudo perf record -e cpu-clock -F 99 -g -p $APP -o perf-plain.data -- sleep 20
sudo perf report -i perf-plain.data --stdio --no-children 2>/dev/null | head -n 30
```

Ubuntu builds with frame pointers, so `-g` works. You see the interpreter's C functions, such as `_PyEval_EvalFrameDefault`, but not which Python function is hot.

### Step 4: Restart with -X perf and record again.

```bash
wait; kill $APP
python3 -X perf ~/shikumi-linux-labs/app/shikumi_api.py --port 8500 & APP=$!
sleep 1
python3 ~/shikumi-linux-labs/app/loadgen.py 'http://127.0.0.1:8500/checksum?kb=256' -c 4 -n 400 &
sudo perf record -e cpu-clock -F 99 -g -p $APP -o perf-py.data -- sleep 20
sudo perf report -f -i perf-py.data --stdio --no-children --sort sym 2>/dev/null > report-py.txt
grep -m 5 'py::' report-py.txt
```

`-X perf` makes Python write `/tmp/perf-PID.map`, which names each Python function as `py::name:file`. The file belongs to you, so root's `perf report` needs `-f` to read it. `py::slow_checksum` is at the top.

### Step 5: Draw a flame graph.

```bash
git clone --depth 1 https://github.com/brendangregg/FlameGraph ~/FlameGraph
sudo perf script -f -i perf-py.data | ~/FlameGraph/stackcollapse-perf.pl | ~/FlameGraph/flamegraph.pl > flame.svg
```

Copy `flame.svg` to the host and open it in a browser. Width is time on CPU. `sudo perf script report flamegraph` is the built-in alternative; it needs perf's Python scripting support.

### Step 6: Fix the hot path and compare.

```bash
wait; kill $APP
SHIKUMI_FAST_CHECKSUM=1 python3 -X perf ~/shikumi-linux-labs/app/shikumi_api.py --port 8500 & APP=$!
sleep 1
python3 ~/shikumi-linux-labs/app/loadgen.py 'http://127.0.0.1:8500/checksum?kb=256' -c 4 -n 400 | tee fast.txt &
sudo perf record -e cpu-clock -F 99 -g -p $APP -o perf-fast.data -- sleep 10
sudo perf report -f -i perf-fast.data --stdio --no-children --sort sym 2>/dev/null > report-fast.txt
wait; kill $APP
grep -E 'rps|p50' slow.txt fast.txt
```

`SHIKUMI_FAST_CHECKSUM=1` swaps the pure-Python loop for `zlib.adler32`, written in C. Same answer, a fraction of the CPU.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Install with `sudo dnf install perf`. Fedora also builds with frame pointers.

> **Debian**
>
> Debian does not build with frame pointers: use `--call-graph dwarf` instead of `-g`. The package is `linux-perf`.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 14.3
```

- `report-py.txt` names `py::slow_checksum`
- `report-fast.txt` exists and does not
- `fast.txt` shows a higher request rate than `slow.txt`

## Stretch challenge

Profile `shikumi-api@8001` while nginx proxies `/checksum` to it. What does perf need to name Python functions in a process you did not start with `-X perf`? (Look up `PYTHONPERFSUPPORT`.)

## Cleanup

```bash
~/shikumi-linux-labs/labs/14.3-perf-and-flame-graphs/cleanup.sh
```

Stops the app on port 8500 and removes the profiles.

## Coreutils used

`head`, `tail`, `tee`, `sleep`, `cut`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
