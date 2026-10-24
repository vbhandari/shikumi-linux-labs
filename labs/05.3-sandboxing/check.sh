#!/bin/bash
# Lab 5.3 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 5.3: Sandbox the service and bind port 80"
d=/etc/systemd/system/shikumi-api.service.d
check "hardening.conf installed" test -f "$d/hardening.conf"
check "no port80.conf left" test ! -e "$d/port80.conf"
check "env file has no SHIKUMI_CACHE lines" bash -c "! grep -q '^SHIKUMI_CACHE' /etc/shikumi/shikumi-api.env"
check "service is active" systemctl is-active --quiet shikumi-api
check "/healthz on 8000 returns 200" test "$(http_status http://127.0.0.1:8000/healthz)" = 200
score="$(systemd-analyze security shikumi-api.service --no-pager 2>/dev/null | awk '/Overall exposure level/ {for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+\.[0-9]+$/) print $i}')"
check "exposure below 5.0 (now ${score:-?})" awk -v s="${score:-99}" 'BEGIN { exit !(s < 5.0) }'
capeff="$(awk '/^CapEff/ {print $2}' "/proc/$(main_pid shikumi-api)/status" 2>/dev/null)"
check "CapEff is CAP_NET_BIND_SERVICE only (${capeff:-?})" test "${capeff:-}" = 0000000000000400
finish
