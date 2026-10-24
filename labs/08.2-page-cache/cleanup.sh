#!/bin/bash
# Lab 8.2 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

W="$LAB_HOME/8.2"
[[ -f "$W/dirty_background_ratio.orig" ]] && as_root sysctl -q vm.dirty_background_ratio="$(cat "$W/dirty_background_ratio.orig")"
rm -rf "$W"
say "Lab 8.2 cleanup done."
