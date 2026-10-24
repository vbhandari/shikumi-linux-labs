#!/bin/bash
# Lab 7.1 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

pkill -u "$USER" -f 'shikumi_api.py --port 8700' 2>/dev/null
as_root pkill -f 'strace -c -f -p' 2>/dev/null
rm -rf "$LAB_HOME/7.1"
say "Lab 7.1 cleanup done."
