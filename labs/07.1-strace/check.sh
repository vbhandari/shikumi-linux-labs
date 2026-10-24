#!/bin/bash
# Lab 7.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 7.1: Watch system calls with strace"
W="$LAB_HOME/7.1"
check "curl.txt shows connect to port 8000" grep -q 'connect(.*htons(8000)' "$W/curl.txt"
check "startup.txt shows pyvenv.cfg" grep -q 'pyvenv.cfg' "$W/startup.txt"
check "count.txt has a summary" grep -q 'total' "$W/count.txt"
finish
