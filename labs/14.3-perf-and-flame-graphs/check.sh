#!/bin/bash
# Lab 14.3 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 14.3: Find the hot function with perf"
W="$LAB_HOME/14.3"
check "report-py.txt names py::slow_checksum" grep -q 'py::slow_checksum' "$W/report-py.txt"
check "report-fast.txt exists" test -s "$W/report-fast.txt"
check "report-fast.txt has no slow_checksum" bash -c "! grep -q slow_checksum '$W/report-fast.txt'"
rps() { grep -o 'rps=[0-9]*' "$1" 2>/dev/null | cut -d= -f2; }
s="$(rps "$W/slow.txt")"; f="$(rps "$W/fast.txt")"
check "fast.txt rps ${f:-?} above slow.txt rps ${s:-?}" test "${f:-0}" -gt "${s:-0}"
finish
