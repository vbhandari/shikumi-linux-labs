#!/bin/bash
# Lab 3.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 3.2: Graceful shutdown, KILL, and a zombie"
port=8302
app="$SHIKUMI_REPO/app/shikumi_api.py"
run_case() {   # run_case SIGNAL -> prints "curl_exit app_exit"
  python3 "$app" --port "$port" >/dev/null 2>&1 & local a=$!
  for _ in $(seq 1 50); do http_status "http://127.0.0.1:$port/healthz" >/dev/null && break; sleep 0.1; done
  curl -s -o /dev/null "http://127.0.0.1:$port/slow?ms=1500" & local c=$!
  sleep 0.5; kill "-$1" "$a"
  wait "$c"; local ce=$?
  wait "$a"; local ae=$?
  echo "$ce $ae"
}
read -r ce ae < <(run_case TERM)
check "TERM: in-flight request completes (curl exit $ce)" test "$ce" = 0
check "TERM: app exits 0 (got $ae)" test "$ae" = 0
read -r ce ae < <(run_case KILL)
check "KILL: app exit status 137 (got $ae)" test "$ae" = 137
if pgrep -u "$USER" -f 'zombie.py|trap.sh' >/dev/null; then bad "no zombie.py or trap.sh left running"; else ok "no zombie.py or trap.sh left running"; fi
finish
