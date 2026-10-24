#!/bin/bash
# Lab 10.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 10.1: CLOSE_WAIT is an application bug"
pid="$(pgrep -u "$USER" -f 'closewait.py' | head -n1)"
check "closewait.py is running" test -n "$pid"
check "it is your copy, without --fixed" bash -c "tr '\0' ' ' < /proc/$pid/cmdline | grep -v -- --fixed | grep -q closewait.py"
for _ in $(seq 1 20); do curl -s -m 2 -o /dev/null http://127.0.0.1:8200/; done
sleep 1
n="$(ss -Htan state close-wait '( sport = :8200 )' | wc -l)"
check "no CLOSE_WAIT sockets after 20 requests ($n)" test "$n" -eq 0
finish
