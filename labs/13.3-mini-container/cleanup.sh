#!/bin/bash
# Lab 13.3 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

as_root ip link delete veth-ctr 2>/dev/null
cg=/sys/fs/cgroup/shikumi-ctr
if [[ -d "$cg" ]]; then
  while read -r p; do as_root kill -9 "$p" 2>/dev/null; done < "$cg/cgroup.procs"
  sleep 1
  as_root rmdir "$cg"
fi
as_root rm -rf "$LAB_HOME/13.3/rootfs"
say "Next: run the cleanup of Lab 13.1."
say "Lab 13.3 cleanup done."
