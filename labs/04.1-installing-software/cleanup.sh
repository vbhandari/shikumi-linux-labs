#!/bin/bash
# Lab 4.1 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

command -v apt-mark >/dev/null && as_root apt-mark unhold nginx >/dev/null 2>&1
rm -rf "$LAB_HOME/4.1"
say "Lab 4.1 cleanup done."
