#!/bin/bash
# Lab 9.3 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 9.3: Capture one request and label every packet"
f="$LAB_HOME/9.3/capture.txt"
check "capture shows SYN" grep -q 'Flags \[S\]' "$f"
check "capture shows SYN-ACK" grep -q 'Flags \[S\.\]' "$f"
check "capture shows data" grep -q 'Flags \[P\.\]' "$f"
check "capture shows FIN" grep -q 'Flags \[F\.\]' "$f"
finish
