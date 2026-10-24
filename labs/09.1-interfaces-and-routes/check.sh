#!/bin/bash
# Lab 9.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 9.1: Map the VM's network"
check "default route exists" bash -c "ip route show default | grep -q ."
ip="$(tr -d '[:space:]' < "$LAB_HOME/9.1/vm-ip.txt" 2>/dev/null)"
check "vm-ip.txt holds a local address (${ip:-empty})" bash -c "[[ -n '$ip' ]] && ip -4 -o addr | grep -q ' $ip/'"
finish
