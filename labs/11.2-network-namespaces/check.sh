#!/bin/bash
# Lab 11.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 11.2: Two network namespaces and a veth pair"
check "namespace blue exists" bash -c "ip netns list | grep -qw blue"
check "namespace red exists" bash -c "ip netns list | grep -qw red"
check "blue has 10.200.0.1" bash -c "sudo ip -n blue -4 -o addr | grep -q ' 10.200.0.1/24'"
check "red can ping blue" as_root ip netns exec red ping -c 1 -W 2 10.200.0.1
check "app in blue answers red" test "$(as_root ip netns exec red curl -s -o /dev/null -w '%{http_code}' -m 3 http://10.200.0.1:8020/healthz)" = 200
finish
