#!/bin/bash
# Lab 2.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 2.1: Disk full, but nothing is big"
check "/mnt/shikumi is mounted" findmnt /mnt/shikumi
if [[ -n "$(as_root lsof +L1 /mnt/shikumi 2>/dev/null)" ]]; then bad "no deleted-but-open files on /mnt/shikumi"; else ok "no deleted-but-open files on /mnt/shikumi"; fi
use="$(df --output=pcent /mnt/shikumi 2>/dev/null | tail -n1 | tr -dc '0-9')"
check "space use below 50% (now ${use:-?}%)" test "${use:-100}" -lt 50
iuse="$(df --output=ipcent /mnt/shikumi 2>/dev/null | tail -n1 | tr -dc '0-9')"
check "inode use below 50% (now ${iuse:-?}%)" test "${iuse:-100}" -lt 50
finish
