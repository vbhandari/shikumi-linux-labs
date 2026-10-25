#!/bin/bash
# Lab 0.1 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

rm -rf "$LAB_HOME/0.1"
say "Lab 0.1 cleanup done."
