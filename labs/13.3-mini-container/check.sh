#!/bin/bash
# Lab 13.3 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 13.3: Build a mini container by hand"
W="$LAB_HOME/13.3"
check "Alpine rootfs present" test -f "$W/rootfs/etc/alpine-release"
out="$(as_root "$W/mini-container.sh" "$W/rootfs" /bin/sh -c 'echo "pid=$$ host=$(hostname)"' 2>&1)"
check "container shell is PID 1 ($out)" grep -q 'pid=1 ' <<<"$out"
check "container host name is shikumi-ctr" grep -q 'host=shikumi-ctr' <<<"$out"
check "cgroup shikumi-ctr has cpu.max 50000 100000" test "$(cat /sys/fs/cgroup/shikumi-ctr/cpu.max 2>/dev/null)" = "50000 100000"
finish
