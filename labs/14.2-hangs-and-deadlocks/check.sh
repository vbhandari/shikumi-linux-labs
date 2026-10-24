#!/bin/bash
# Lab 14.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 14.2: Prove a deadlock and fix the lock order"
W="$LAB_HOME/14.2"
check "stacks.txt shows the transfer thread" grep -q 'in transfer' "$W/stacks.txt"
check "stacks.txt shows the report thread" grep -q 'in report' "$W/stacks.txt"
out="$(timeout 7 python3 "$W/deadlock.py" 2>/dev/null)"
mapfile -t counts < <(grep -o 'transfers=[0-9]*' <<<"$out" | cut -d= -f2 | tail -n 3)
if [[ ${#counts[@]} -eq 3 && ${counts[0]} -lt ${counts[1]} && ${counts[1]} -lt ${counts[2]} ]]; then
  ok "your deadlock.py keeps counting (${counts[*]})"
else
  bad "your deadlock.py keeps counting (${counts[*]:-no output})"
fi
finish
