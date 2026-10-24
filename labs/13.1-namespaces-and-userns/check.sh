#!/bin/bash
# Lab 13.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 13.1: Namespaces, and who may create them"
check "userns restriction is still 1" test "$(sysctl -n kernel.apparmor_restrict_unprivileged_userns 2>/dev/null)" = 1
check "shikumi-unshare installed" test -x /usr/local/bin/shikumi-unshare
check "shikumi-unshare profile loaded" bash -c "sudo grep -q '^shikumi-unshare ' /sys/kernel/security/apparmor/profiles"
check "shikumi-unshare -r maps you to root" test "$(/usr/local/bin/shikumi-unshare -r id -u 2>/dev/null)" = 0
if unshare -r true 2>/dev/null; then bad "plain unshare -r is still refused"; else ok "plain unshare -r is still refused"; fi
finish
