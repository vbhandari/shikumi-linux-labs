#!/bin/bash
# Lab 15.2 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

as_root "$(lab_dir 15.2)/break.sh" --undo
rm -rf "$LAB_HOME/15.2"
say "Lab 15.2 cleanup done."
