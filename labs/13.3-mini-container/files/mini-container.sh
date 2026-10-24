#!/bin/bash
# Steps 2-6 of Lab 13.3 in one script: a shell in new namespaces, with ROOTFS as its root.
# Usage: sudo ./mini-container.sh ROOTFS [command...]
#        ./mini-container.sh --rootless ROOTFS [command...]   (needs shikumi-unshare, Lab 13.1)
set -euo pipefail
unshare=(unshare)
if [[ "${1:-}" == --rootless ]]; then unshare=(shikumi-unshare -r); shift; fi
rootfs="$(readlink -f "${1:?usage: mini-container.sh [--rootless] ROOTFS [command...]}")"
shift
[[ $# -gt 0 ]] || set -- /bin/sh

exec "${unshare[@]}" --mount --uts --ipc --net --pid --fork bash -c '
  set -e
  hostname shikumi-ctr
  mount --bind "$1" "$1"
  cd "$1"
  mkdir -p .old
  pivot_root . .old
  hash -r
  mount -t proc proc /proc
  umount -l /.old
  rmdir /.old
  shift
  exec "$@"' mini-container "$rootfs" "$@"
