#!/bin/bash
# Lab 11.4 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

as_root ip netns exec blue tc qdisc del dev veth-blue root 2>/dev/null
as_root pkill -x iperf3 2>/dev/null
say "Next: run the cleanups of Lab 11.3, then Lab 11.2."
rm -rf "$LAB_HOME/11.4"
say "Lab 11.4 cleanup done."
