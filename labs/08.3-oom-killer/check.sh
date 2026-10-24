#!/bin/bash
# Lab 8.3 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 8.3: The OOM killer and memory limits"
check "kernel log shows a cgroup OOM" bash -c "sudo journalctl -k -q --no-pager -g 'Memory cgroup out of memory' | grep -q ."
if systemctl is-active --quiet shikumi-oom.scope; then bad "no shikumi-oom scope left running"; else ok "no shikumi-oom scope left running"; fi
finish
