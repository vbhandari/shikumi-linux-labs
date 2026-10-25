#!/bin/bash
# Lab 12.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 12.1: nginx in front of two instances"
check "nginx is enabled" systemctl is-enabled --quiet nginx
check "nginx is active" systemctl is-active --quiet nginx
check "nginx -t passes" as_root nginx -t
check "ufw allows 80/tcp" bash -c "sudo ufw status | grep -q '^80/tcp .*ALLOW'"
if [[ "$(http_status http://127.0.0.1/healthz)" == 301 ]]; then
  note "port 80 redirects to HTTPS: the Lab 12.2 TLS site is installed"
  note "skipped: responses from two PIDs, and /alloc refused on port 80"
  note "Lab 12.2's check tests HTTPS: shikumi-check lab 12.2"
else
  out="$(python3 "$SHIKUMI_REPO/app/loadgen.py" http://127.0.0.1/healthz -c 10 -n 200 --by-pid 2>&1)"
  n="$(grep -o 'by_pid={.*}' <<<"$out" | grep -o ':' | wc -l)"
  check "responses came from two PIDs ($n)" test "$n" -eq 2
  check "nginx refuses /alloc (404)" test "$(http_status 'http://127.0.0.1/alloc?mb=0')" = 404
fi
finish
