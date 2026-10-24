#!/bin/bash
# Lab 14.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 14.1: The first 60 seconds"
W="$LAB_HOME/14.1"
real="$(sudo cat /run/shikumi-mystery.answer 2>/dev/null)"
if [[ -z "$real" ]]; then bad "a mystery is running (sudo ./mystery.sh)"; finish; fi
mine="$(tr -d '[:space:]' < "$W/answer.txt" 2>/dev/null)"
check "answer.txt names the problem (yours: ${mine:-empty})" test "$mine" = "$real"
finish
