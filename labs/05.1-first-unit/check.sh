#!/bin/bash
# Lab 5.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 5.1: Install the app as a systemd service"
check "app installed 0755 root" test "$(stat -c '%a %U' /opt/shikumi/bin/shikumi-api 2>/dev/null)" = "755 root"
check "shikumi-api is enabled" systemctl is-enabled --quiet shikumi-api
check "shikumi-api is active" systemctl is-active --quiet shikumi-api
check "runs as shikumi" test "$(systemctl show -p User --value shikumi-api)" = shikumi
check "/healthz returns 200" test "$(http_status http://127.0.0.1:8000/healthz)" = 200
check "/data returns 200" test "$(http_status 'http://127.0.0.1:8000/data?name=hello.txt')" = 200
pid="$(main_pid shikumi-api)"
check "Max open files is 4096" bash -c "grep -q 'Max open files *4096 *4096' /proc/$pid/limits"
finish
