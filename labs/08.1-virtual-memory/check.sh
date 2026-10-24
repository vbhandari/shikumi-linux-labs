#!/bin/bash
# Lab 8.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 8.1: RSS, VSZ and a memory-mapped file"
W="$LAB_HOME/8.1"
check "big.bin exists" test -f "$W/big.bin"
t="$(mktemp -p "$HOME" mmapcheck.XXXX)"
out="$(python3 "$SHIKUMI_REPO/app/mmapdemo.py" "$t" --mb 64 --step-mb 64 --batch)"
rm -f "$t"
read -r vs1 rs1 < <(awk '/^before/ {gsub(/[^0-9 ]/, " "); print $1, $2}' <<<"$out")
read -r vs2 rs2 < <(awk '/^after/ {gsub(/[^0-9 ]/, " "); print $1, $2}' <<<"$out")
check "VmSize unchanged ($vs1 -> $vs2 kB)" test "${vs1:-0}" = "${vs2:-1}"
check "VmRSS grew by 50 MB or more ($rs1 -> $rs2 kB)" test $(( ${rs2:-0} - ${rs1:-0} )) -ge 51200
finish
