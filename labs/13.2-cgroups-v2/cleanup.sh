#!/bin/bash
# Lab 13.2 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

as_root systemctl stop shikumi-burn 2>/dev/null
as_root systemctl reset-failed shikumi-burn 2>/dev/null
cg=/sys/fs/cgroup/shikumi
if [[ -d "$cg" ]]; then
  while read -r p; do as_root kill "$p" 2>/dev/null; done < "$cg/cgroup.procs"
  sleep 1
  as_root rmdir "$cg"
fi
rm -rf "$LAB_HOME/13.2"
say "Lab 13.2 cleanup done."
