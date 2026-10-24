#!/bin/bash
# Lab 13.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 13.2: Throttle a busy loop with cgroups v2"
cg=/sys/fs/cgroup/shikumi
check "cgroup $cg exists" test -d "$cg"
check "cpu.max is 20000 100000" test "$(cat "$cg/cpu.max" 2>/dev/null)" = "20000 100000"
n="$(awk '/^nr_throttled/ {print $2}' "$cg/cpu.stat" 2>/dev/null)"
check "nr_throttled above 0 (${n:-?})" test "${n:-0}" -gt 0
if systemctl is-active --quiet shikumi-burn; then bad "shikumi-burn stopped"; else ok "shikumi-burn stopped"; fi
finish
