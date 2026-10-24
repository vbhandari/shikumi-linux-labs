#!/bin/bash
# Lab 9.2 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

as_root sed -i '/# shikumi-lab$/d' /etc/hosts
say "Lab 9.2 cleanup done."
