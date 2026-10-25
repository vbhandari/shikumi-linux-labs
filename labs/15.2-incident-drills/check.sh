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
# Labels stay generic on purpose: the output must not name the faults.
lim="$(systemctl show -p LimitNOFILE --value shikumi-api@8001)"
check "fault 1 cleared" test "${lim:-0}" -ge 1024
check "fault 2 cleared" test "$(ss -Htan state close-wait | wc -l)" -eq 0
fs=/var/log/shikumi-drill
if findmnt "$fs" >/dev/null; then
  check "fault 3 cleared" bash -c "[[ -z \$(sudo lsof -a +L1 $fs 2>/dev/null) ]] && (( \$(df --output=pcent $fs | tail -n1 | tr -dc '0-9') < 90 ))"
else
  ok "fault 3 cleared"
fi
check "fault 4 cleared" test "$(http_status "http://127.0.0.1:8002/data?name=hello.txt")" = 200
check "fault 5 cleared" test "$(systemctl show -p MemoryMax --value shikumi-api@8001)" = 268435456
if systemctl is-active --quiet shikumi-drill-6; then
  check "fault 6 cleared" bash -c "systemctl show -p Environment shikumi-api@8001 | grep -q SHIKUMI_FAST_CHECKSUM=1"
else
  ok "fault 6 cleared"
fi
if tc qdisc show dev lo | grep -q netem; then bad "fault 7 cleared"; else ok "fault 7 cleared"; fi
p50="$(python3 "$SHIKUMI_REPO/app/loadgen.py" http://127.0.0.1:8001/healthz -c 2 -n 20 --timeout 2 | grep -o 'p50=[0-9]*' | cut -d= -f2)"
check "p50 to @8001 below 50 ms" test "${p50:-999}" -lt 50
finish
