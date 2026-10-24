#!/bin/bash
# Lab 8.3 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

as_root systemctl stop shikumi-oom.scope 2>/dev/null
as_root systemctl reset-failed shikumi-oom.scope 2>/dev/null
pkill -u "$USER" -f alloc.py 2>/dev/null
say "Lab 8.3 cleanup done."
