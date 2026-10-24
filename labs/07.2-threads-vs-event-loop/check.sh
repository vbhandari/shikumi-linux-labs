#!/bin/bash
# Lab 7.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 7.2: How servers wait: an event loop and a thread pool"
W="$LAB_HOME/7.2"
check "async.txt shows epoll_wait" grep -q 'epoll_wait' "$W/async.txt"
check "async.txt shows accept4" grep -q 'accept4' "$W/async.txt"
check "threads.txt shows clone3" grep -Eq 'clone3?\(' "$W/threads.txt"
n="$(awk '{print $1}' "$W/threads.txt" 2>/dev/null | sort -u | wc -l)"
check "threads.txt has more than five thread IDs ($n)" test "$n" -gt 5
finish
