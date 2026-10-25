#!/bin/bash
# Lab 11.2 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

pkill -u "$USER" -f 'shikumi_api.py --host 10.200.0.1' 2>/dev/null
for ns in blue red; do as_root ip netns delete "$ns" 2>/dev/null; done
rm -rf "$LAB_HOME/11.2"
say "Lab 11.2 cleanup done."
