#!/bin/bash
# Lab 1.3 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 1.3: Configure the app from the environment and reach it over SSH"
check "app answers on 127.0.0.1:8080" test "$(http_status http://127.0.0.1:8080/healthz)" = 200
pid="$(pgrep -u "$USER" -f 'shikumi_api.py' | head -n1)"
if [[ -n "$pid" ]] && tr '\0' '\n' < "/proc/$pid/environ" | grep -qx 'SHIKUMI_PORT=8080'; then
  ok "the app got SHIKUMI_PORT=8080 from its environment"
else
  bad "the app got SHIKUMI_PORT=8080 from its environment"
fi
finish
