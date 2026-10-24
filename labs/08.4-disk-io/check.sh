#!/bin/bash
# Lab 8.4 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 8.4: The cost of fsync"
W="$LAB_HOME/8.4"
iops() {   # first "write: IOPS=12.3k" value in a file, as a number
  grep -m1 -o 'IOPS=[0-9.]*[kM]\?' "$1" 2>/dev/null | awk -F= '{v=$2; m=1; if (v ~ /k$/) m=1000; if (v ~ /M$/) m=1000000; sub(/[kM]$/, "", v); printf "%d\n", v*m}'
}
b="$(iops "$W/buffered.txt")"; f="$(iops "$W/fsync.txt")"
check "buffered.txt has results (${b:-none} IOPS)" test -n "$b"
check "fsync.txt has results (${f:-none} IOPS)" test -n "$f"
check "fsync IOPS lower than buffered" test "${f:-1}" -lt "${b:-0}"
finish
