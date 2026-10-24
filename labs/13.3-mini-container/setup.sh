#!/bin/bash
# Lab 13.3 setup: copy the lab files to ~/labs/13.3 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 13.3
W="$LAB_HOME/13.3"
version=3.24.3
arch="$(uname -m)"
case "$arch" in
  x86_64) sum=f8e1cafba9b1b283b5d30d06f9885c8d2bc161ffe9083ade8e2e157813a53407 ;;
  aarch64) sum=4d3f80afaebd447c5591a63a73bde380a149fe8b2d85488cafabb2ff97551f50 ;;
  *) say "no Alpine checksum for $arch"; exit 1 ;;
esac
tarball="alpine-minirootfs-$version-$arch.tar.gz"
if [[ ! -f "$W/rootfs/etc/alpine-release" ]]; then
  curl -fsSL -o "$W/$tarball" "https://dl-cdn.alpinelinux.org/alpine/v${version%.*}/releases/$arch/$tarball"
  echo "$sum  $W/$tarball" | sha256sum -c -
  mkdir -p "$W/rootfs"
  tar -xzf "$W/$tarball" -C "$W/rootfs"
  rm -f "$W/$tarball"
fi
say "Alpine $(cat "$W/rootfs/etc/alpine-release") is in $W/rootfs"
if [[ ! -x /usr/local/bin/shikumi-unshare ]]; then
  ensure_shikumi_unshare
  say "Reinstalled shikumi-unshare from Lab 13.1, for the stretch"
fi
