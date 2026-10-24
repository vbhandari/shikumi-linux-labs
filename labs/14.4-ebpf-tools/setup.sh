#!/bin/bash
# Lab 14.4 setup: copy the lab files to ~/labs/14.4 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 14.4
need_cmd bpftrace
check "kernel BTF present" test -r /sys/kernel/btf/vmlinux
