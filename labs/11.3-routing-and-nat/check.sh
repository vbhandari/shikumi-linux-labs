#!/bin/bash
# Lab 11.3 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 11.3: Route and NAT out of a namespace"
code="$(as_root ip netns exec blue curl -s -m 5 -o /dev/null -w '%{http_code}' http://1.1.1.1/ 2>/dev/null)"
check "blue reaches http://1.1.1.1/ over TCP (${code:-000})" test "${code:-000}" != 000
check "nat table loaded" bash -c "sudo nft list table ip shikumi_nat 2>/dev/null | grep -q masquerade"
check "ufw route rule present" bash -c "sudo ufw status | grep -q 'on veth-host'"
finish
