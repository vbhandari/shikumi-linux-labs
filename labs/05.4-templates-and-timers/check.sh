#!/bin/bash
# Lab 5.4 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 5.4: Two instances from one template, and a timer"
for p in 8001 8002; do
  check "shikumi-api@$p is enabled" systemctl is-enabled --quiet "shikumi-api@$p"
  check "shikumi-api@$p is active" systemctl is-active --quiet "shikumi-api@$p"
  check "port $p answers 200" test "$(http_status "http://127.0.0.1:$p/healthz")" = 200
done
check "the two instances have different PIDs" test "$(main_pid shikumi-api@8001)" != "$(main_pid shikumi-api@8002)"
check "shikumi-prune.timer is enabled" systemctl is-enabled --quiet shikumi-prune.timer
check "shikumi-prune.timer is active" systemctl is-active --quiet shikumi-prune.timer
check "last prune run succeeded" test "$(systemctl show -p Result --value shikumi-prune.service)" = success
check "old.tmp was pruned" test ! -e /var/lib/shikumi/old.tmp
finish
