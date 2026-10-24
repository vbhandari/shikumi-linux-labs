#!/bin/bash
# Lab 10.3 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 10.3: SO_REUSEPORT, SO_REUSEADDR and EADDRINUSE"
W="$LAB_HOME/10.3"
n="$(grep -o 'by_pid={.*}' "$W/reuseport.txt" 2>/dev/null | grep -o ':' | wc -l)"
check "reuseport.txt shows two PIDs ($n)" test "$n" -eq 2
out="$(cd "$W" && python3 bind_test.py 2>&1)"
check "without SO_REUSEADDR: Errno 98" grep -q 'SO_REUSEADDR=0: \[Errno 98\]' <<<"$out"
check "with SO_REUSEADDR: bind ok" grep -q 'SO_REUSEADDR=1: bind ok' <<<"$out"
finish
