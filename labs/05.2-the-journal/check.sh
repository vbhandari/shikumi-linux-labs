#!/bin/bash
# Lab 5.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 5.2: Find the crash in the journal"
check "journal is persistent" test -d /var/log/journal
check "journal has shikumi-api entries" bash -c "sudo journalctl -u shikumi-api -q --no-pager | grep -q ."
check "journal shows the crash from Lab 5.1" bash -c "sudo journalctl -u shikumi-api -q --no-pager | grep -q 'Main process exited'"
check "a shikumi-lab entry exists" bash -c "sudo journalctl -t shikumi-lab -q --no-pager | grep -q ."
finish
