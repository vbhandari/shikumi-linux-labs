#!/bin/bash
# Lab 5.4 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

as_root find /var/lib/shikumi -maxdepth 1 -name '*.tmp' -delete 2>/dev/null
rm -rf "$LAB_HOME/5.4"
say "Lab 5.4 cleanup done."
