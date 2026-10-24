#!/bin/bash
# Lab 10.3 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

pkill -u "$USER" -f 'shikumi_api.py --port 840[01]' 2>/dev/null
rm -rf "$LAB_HOME/10.3"
say "Lab 10.3 cleanup done."
