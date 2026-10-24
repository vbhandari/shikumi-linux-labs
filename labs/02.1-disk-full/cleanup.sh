#!/bin/bash
# Lab 2.1 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

pkill -u "$USER" -f holdlog.py 2>/dev/null
sleep 0.5
findmnt /mnt/shikumi >/dev/null && as_root umount /mnt/shikumi
[[ -d /mnt/shikumi ]] && as_root rmdir /mnt/shikumi
rm -f "$LAB_HOME/2.1/disk.img"
say "Lab 2.1 cleanup done."
