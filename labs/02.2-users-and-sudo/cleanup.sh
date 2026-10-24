#!/bin/bash
# Lab 2.2 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

as_root rm -f /etc/sudoers.d/90-shikumi-deploy
getent passwd deployer >/dev/null && as_root userdel -r deployer 2>/dev/null
rm -rf "$LAB_HOME/2.2"
say "Lab 2.2 cleanup done."
