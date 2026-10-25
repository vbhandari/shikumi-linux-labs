#!/bin/bash
# Lab 5.3 setup: copy the lab files to ~/labs/5.3 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 5.3
# Start with a clean start-limit counter: Lab 5.1 just used several starts.
as_root systemctl reset-failed 'shikumi-api*' 2>/dev/null || true
