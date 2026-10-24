#!/bin/bash
# Lab 14.2 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

pkill -u "$USER" -f deadlock.py 2>/dev/null
rm -rf "$LAB_HOME/14.2"
say "Lab 14.2 cleanup done."
