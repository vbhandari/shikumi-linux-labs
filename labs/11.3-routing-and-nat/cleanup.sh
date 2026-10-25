#!/bin/bash
# Lab 11.3 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

W="$LAB_HOME/11.3"
as_root nft delete table ip shikumi_nat 2>/dev/null
as_root nft delete table inet shikumi_trace 2>/dev/null
up="$(uplink)"
command -v ufw >/dev/null && as_root ufw route delete allow in on veth-host out on "$up" >/dev/null 2>&1
as_root ip link delete veth-host 2>/dev/null
as_root rm -rf /etc/netns/blue
[[ -f "$W/ip_forward.orig" ]] && as_root sysctl -q -w net.ipv4.ip_forward="$(cat "$W/ip_forward.orig")"
rm -rf "$LAB_HOME/11.3"
say "Lab 11.3 cleanup done."
