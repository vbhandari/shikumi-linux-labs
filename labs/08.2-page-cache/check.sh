#!/bin/bash
# Lab 8.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 8.2: Page cache and dirty pages"
W="$LAB_HOME/8.2"
check "data.bin exists" test -f "$W/data.bin"
if [[ -f "$W/dirty_background_ratio.orig" ]]; then
  check "dirty_background_ratio restored" test "$(sysctl -n vm.dirty_background_ratio)" = "$(cat "$W/dirty_background_ratio.orig")"
else
  bad "dirty_background_ratio.orig saved (step 4)"
fi
finish
