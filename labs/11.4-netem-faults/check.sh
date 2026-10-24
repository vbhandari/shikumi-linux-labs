#!/bin/bash
# Lab 11.4 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 11.4: Inject delay and loss with tc netem"
W="$LAB_HOME/11.4"
p50() { grep -o 'p50=[0-9.]*' "$1" 2>/dev/null | cut -d= -f2 | cut -d. -f1; }
a="$(p50 "$W/before.txt")"; b="$(p50 "$W/netem.txt")"
check "before.txt has results (p50 ${a:-?} ms)" test -n "$a"
check "netem.txt has results (p50 ${b:-?} ms)" test -n "$b"
check "p50 rose by at least 90 ms" test $(( ${b:-0} - ${a:-0} )) -ge 90
if as_root ip netns exec blue tc qdisc show dev veth-blue 2>/dev/null | grep -q netem; then bad "no netem qdisc left on veth-blue"; else ok "no netem qdisc left on veth-blue"; fi
finish
