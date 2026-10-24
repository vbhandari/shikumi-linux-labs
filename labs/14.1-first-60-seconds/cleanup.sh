#!/bin/bash
# Lab 14.1 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

as_root "$LAB_HOME/14.1/mystery.sh" --stop >/dev/null 2>&1 || as_root "$(lab_dir 14.1)/files/mystery.sh" --stop >/dev/null 2>&1
rm -rf "$LAB_HOME/14.1"
say "Lab 14.1 cleanup done."
