#!/bin/bash
# Lab 14.4 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 14.4: eBPF: ready-made tools, then your own"
W="$LAB_HOME/14.4"
check "kernel BTF present" test -r /sys/kernel/btf/vmlinux
for f in openat_by_comm.bt request_latency.bt; do
  check "$f has no TODO left" bash -c "! grep -q TODO '$W/$f'"
  check "$f passes bpftrace --dry-run" as_root timeout 30 bpftrace --dry-run "$W/$f"
done
finish
