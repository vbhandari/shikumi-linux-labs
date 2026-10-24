#!/bin/bash
# Lab 10.4 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 10.4: Socket buffers and autotuning"
W="$LAB_HOME/10.4"
if [[ -f "$W/tcp_rmem.orig" ]]; then
  check "tcp_rmem restored" test "$(sysctl -n net.ipv4.tcp_rmem)" = "$(cat "$W/tcp_rmem.orig")"
else
  bad "tcp_rmem.orig saved (step 3)"
fi
check "default.txt has results" grep -q receiver "$W/default.txt"
check "small.txt has results" grep -q receiver "$W/small.txt"
finish
