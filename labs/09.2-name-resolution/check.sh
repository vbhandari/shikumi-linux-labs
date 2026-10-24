#!/bin/bash
# Lab 9.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 9.2: Override a name and find the resolver"
check "getent finds api.shikumi.test at 10.200.9.9" bash -c "getent hosts api.shikumi.test | grep -q '^10.200.9.9 '"
check "resolv.conf uses the stub resolver" grep -q '^nameserver 127.0.0.53' /etc/resolv.conf
finish
