#!/bin/bash
# Lab 6.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 6.2: Complain, refine, enforce: confine both instances"
prof=/opt/shikumi/bin/shikumi-api
check "profile in enforce mode" bash -c "sudo cat /sys/kernel/security/apparmor/profiles | grep -qx '$prof (enforce)'"
for p in 8001 8002; do
  label="$(sudo cat "/proc/$(main_pid "shikumi-api@$p")/attr/current" 2>/dev/null | tr -d '\0')"
  check "shikumi-api@$p is confined (${label:-none})" test "$label" = "$prof (enforce)"
  check "port $p /data returns 200" test "$(http_status "http://127.0.0.1:$p/data?name=hello.txt")" = 200
done
check "cache file written" test -f /var/cache/shikumi/hello.txt.cache
finish
