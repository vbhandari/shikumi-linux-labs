#!/bin/bash
# Lab 3.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 3.1: Profile a process through /proc, and watch fork and exec"
W="$LAB_HOME/3.1"
check "status.txt has PPid" grep -q '^PPid:' "$W/status.txt"
check "fork.txt shows execve" grep -q 'execve(' "$W/fork.txt"
check "fork.txt shows clone or clone3" grep -Eq 'clone3?\(' "$W/fork.txt"
finish
