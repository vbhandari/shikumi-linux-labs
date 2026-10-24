#!/bin/bash
# Lab 7.2 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

pkill -u "$USER" -f threaded_api.py 2>/dev/null
as_root pkill -f 'strace -f -tt -p' 2>/dev/null
rm -rf "$LAB_HOME/7.2"
say "Lab 7.2 cleanup done."
