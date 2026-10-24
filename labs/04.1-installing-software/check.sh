#!/bin/bash
# Lab 4.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 4.1: Install nginx and find everything it brought"
check "nginx is installed" bash -c "dpkg-query -W -f='\${Status}' nginx 2>/dev/null | grep -q 'install ok installed' || rpm -q nginx"
check "nginx.service is disabled" test "$(systemctl is-enabled nginx 2>/dev/null)" = disabled
check "nginx.service is inactive" test "$(systemctl is-active nginx 2>/dev/null)" = inactive
if ss -Htln 'sport = :80' | grep -q .; then bad "port 80 is free"; else ok "port 80 is free"; fi
if command -v apt-mark >/dev/null && apt-mark showhold | grep -qx nginx; then bad "nginx is not held"; else ok "nginx is not held"; fi
finish
