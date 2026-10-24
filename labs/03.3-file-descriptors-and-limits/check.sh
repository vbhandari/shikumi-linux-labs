#!/bin/bash
# Lab 3.3 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 3.3: Run out of file descriptors"
app="$SHIKUMI_REPO/app/shikumi_api.py"
try_limit() {   # try_limit N -> prints the HTTP status of /files?n=100
  local port=8303 a out
  (ulimit -n "$1"; exec python3 "$app" --port "$port") >/dev/null 2>&1 & a=$!
  for _ in $(seq 1 50); do http_status "http://127.0.0.1:$port/healthz" >/dev/null && break; sleep 0.1; done
  out="$(curl -s -w ' %{http_code}' "http://127.0.0.1:$port/files?n=100" | tr -d '\n')"
  kill "$a"; wait "$a" 2>/dev/null
  echo "$out"
}
low="$(try_limit 64)"
check "limit 64: /files?n=100 fails with Errno 24" grep -q 'Errno 24.* 500$' <<<"$low"
high="$(try_limit 4096)"
check "limit 4096: /files?n=100 returns 200" grep -q ' 200$' <<<"$high"
finish
