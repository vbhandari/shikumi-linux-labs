#!/bin/bash
# Lab 3.1 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

pkill -u "$USER" -f 'shikumi_api.py' 2>/dev/null
rm -rf "$LAB_HOME/3.1"
say "Lab 3.1 cleanup done."
