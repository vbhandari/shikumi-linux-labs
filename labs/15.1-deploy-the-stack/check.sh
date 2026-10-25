#!/bin/bash
# Lab 15.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 15.1: Deploy the production-shaped stack"
prof=/opt/shikumi/bin/shikumi-api
check "AppArmor profile in enforce mode" bash -c "sudo cat /sys/kernel/security/apparmor/profiles | grep -qx '$prof (enforce)'"
for p in 8001 8002; do
  u="shikumi-api@$p"
  check "$u enabled" systemctl is-enabled --quiet "$u"
  check "$u active" systemctl is-active --quiet "$u"
  label="$(sudo cat "/proc/$(main_pid "$u")/attr/current" 2>/dev/null | tr -d '\0')"
  check "$u confined" test "$label" = "$prof (enforce)"
done
score="$(systemd-analyze security shikumi-api@8001.service --no-pager 2>/dev/null | awk '/Overall exposure level/ {for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+\.[0-9]+$/) print $i}')"
check "exposure below 5.0 (${score:-?})" awk -v s="${score:-99}" 'BEGIN { exit !(s < 5.0) }'
ca=/etc/nginx/shikumi-tls/ca.crt
check "HTTPS over HTTP/2 returns 200" test "$(curl -s --cacert "$ca" -o /dev/null -w '%{http_version} %{http_code}' https://localhost/healthz)" = "2 200"
check "HTTP redirects with 301" test "$(http_status http://127.0.0.1/healthz)" = 301
a="$(curl -s --cacert "$ca" -o /dev/null -w '%{http_code}' 'https://localhost/alloc?mb=0')"
check "nginx refuses /alloc ($a)" test "$a" = 404
for p in 8001 8002; do
  mm="$(systemctl show -p MemoryMax --value "shikumi-api@$p")"
  check "shikumi-api@$p MemoryMax=256M ($mm)" test "$mm" = 268435456
  tm="$(systemctl show -p TasksMax --value "shikumi-api@$p")"
  check "shikumi-api@$p TasksMax=64 ($tm)" test "$tm" = 64
done
st="$(sudo ufw status 2>/dev/null)"
check "ufw active" grep -q '^Status: active' <<<"$st"
for r in OpenSSH 80/tcp 443/tcp; do check "ufw allows $r" grep -q "^$r .*ALLOW" <<<"$st"; done
if systemctl is-active --quiet shikumi-ufw-revert.timer; then bad "ufw undo timer stopped"; else ok "ufw undo timer stopped"; fi
check "journal is persistent" test -d /var/log/journal
check "shikumi-prune.timer active" systemctl is-active --quiet shikumi-prune.timer
finish
