#!/bin/bash
# Lab 11.3 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 11.3: Route and NAT out of a namespace"
check "blue can ping 1.1.1.1" as_root ip netns exec blue ping -c 1 -W 3 1.1.1.1
check "nat table loaded" bash -c "sudo nft list table ip shikumi_nat 2>/dev/null | grep -q masquerade"
check "ufw route rule present" bash -c "sudo ufw status | grep -q 'on veth-host'"
finish
