#!/bin/bash
# Lab 1.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 1.2: Answer five questions from an access log"
W="$LAB_HOME/1.2"
cd "$W" 2>/dev/null || { bad "$W exists (run setup.sh)"; finish; }
check "access.log exists" test -s access.log
answer() { sed -n "s/^$1=//p" answers.txt | tr -d '[:space:]'; }
expect() {
  local got; got="$(answer "$1")"
  if [[ -n "$got" && "$got" == "$2" ]]; then ok "$1 = $got"; else bad "$1 (yours: '${got}')"; fi
}
expect total_requests "$(wc -l < access.log | tr -d ' ')"
expect server_errors "$(awk '$9 >= 500' access.log | wc -l | tr -d ' ')"
expect top_path "$(awk '{print $7}' access.log | sort | uniq -c | sort -rn | awk 'NR==1 {print $2}')"
expect top_ip "$(awk '{print $1}' access.log | sort | uniq -c | sort -rn | awk 'NR==1 {print $2}')"
expect slowest_path "$(sort -k11,11 -rn access.log | awk 'NR==1 {print $7}')"
finish
