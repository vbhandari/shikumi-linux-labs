#!/bin/bash
# Lab 9.3 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

rm -rf "$LAB_HOME/9.3"
say "Lab 9.3 cleanup done."
