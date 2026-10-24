#!/bin/bash
# Lab 14.3 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

pkill -u "$USER" -f 'shikumi_api.py --port 8500' 2>/dev/null
as_root rm -f "$LAB_HOME"/14.3/perf-*.data "$LAB_HOME"/14.3/perf-*.data.old
rm -rf "$LAB_HOME/14.3"
say "Lab 14.3 cleanup done."
