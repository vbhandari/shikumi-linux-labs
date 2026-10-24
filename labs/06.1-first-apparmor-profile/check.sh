#!/bin/bash
# Lab 6.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 6.1: Generate an AppArmor profile for the app"
prof=/opt/shikumi/bin/shikumi-api
check "profile loaded in enforce mode" bash -c "sudo cat /sys/kernel/security/apparmor/profiles | grep -qx '$prof (enforce)'"
label="$(sudo cat "/proc/$(main_pid shikumi-api)/attr/current" 2>/dev/null | tr -d '\0')"
check "shikumi-api.service is confined (${label:-none})" test "$label" = "$prof (enforce)"
check "/data returns 200" test "$(http_status 'http://127.0.0.1:8000/data?name=hello.txt')" = 200
check "a DENIED line exists for the profile" bash -c "sudo journalctl -k -q --no-pager -g 'apparmor=\"DENIED\"' | grep -q 'profile=\"$prof\"'"
check "data-dir.conf removed" test ! -e /etc/systemd/system/shikumi-api.service.d/data-dir.conf
finish
