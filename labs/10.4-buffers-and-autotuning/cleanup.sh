#!/bin/bash
# Lab 10.4 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

W="$LAB_HOME/10.4"
[[ -f "$W/tcp_rmem.orig" ]] && as_root sysctl -q -w net.ipv4.tcp_rmem="$(cat "$W/tcp_rmem.orig")"
pkill -u "$USER" -x iperf3 2>/dev/null
rm -rf "$W"
say "Lab 10.4 cleanup done."
