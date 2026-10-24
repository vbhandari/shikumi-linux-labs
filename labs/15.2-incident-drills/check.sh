#!/bin/bash
# Lab 15.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 15.2: Incident drills"
for p in 8001 8002; do
  check "shikumi-api@$p active" systemctl is-active --quiet "shikumi-api@$p"
  check "port $p /data returns 200" test "$(http_status "http://127.0.0.1:$p/data?name=hello.txt")" = 200
done
check "HTTPS returns 200" test "$(curl -s -m 5 --cacert /etc/nginx/shikumi-tls/ca.crt -o /dev/null -w '%{http_code}' https://localhost/healthz)" = 200
lim="$(systemctl show -p LimitNOFILE --value shikumi-api@8001)"
check "drill 1: @8001 file limit is not tiny ($lim)" test "${lim:-0}" -ge 1024
n="$(ss -Htan state close-wait | wc -l)"
check "drill 2: no CLOSE_WAIT sockets ($n)" test "$n" -eq 0
if findmnt /var/log/shikumi-drill >/dev/null; then
  check "drill 3: no deleted-but-open files" bash -c "[[ -z \$(sudo lsof +L1 /var/log/shikumi-drill 2>/dev/null) ]]"
  use="$(df --output=pcent /var/log/shikumi-drill | tail -n1 | tr -dc '0-9')"
  check "drill 3: drill filesystem below 90% ($use%)" test "$use" -lt 90
else
  ok "drill 3: no drill filesystem mounted"
fi
check "drill 5: @8001 has no memory cap" test "$(systemctl show -p MemoryMax --value shikumi-api@8001)" = infinity
if systemctl is-active --quiet shikumi-drill-load; then
  check "drill 6: runaway load stopped, or the hot path fixed" bash -c "systemctl show -p Environment shikumi-api@8001 | grep -q SHIKUMI_FAST_CHECKSUM=1"
else
  ok "drill 6: no runaway load"
fi
if tc qdisc show dev lo | grep -q netem; then bad "drill 7: no netem on lo"; else ok "drill 7: no netem on lo"; fi
p50="$(python3 "$SHIKUMI_REPO/app/loadgen.py" http://127.0.0.1:8001/healthz -c 2 -n 20 --timeout 2 | grep -o 'p50=[0-9]*' | cut -d= -f2)"
check "p50 to @8001 below 50 ms (${p50:-?})" test "${p50:-999}" -lt 50
finish
