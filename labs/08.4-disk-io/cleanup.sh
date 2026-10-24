#!/bin/bash
# Lab 8.4 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

rm -rf "$LAB_HOME/8.4"
say "Lab 8.4 cleanup done."
