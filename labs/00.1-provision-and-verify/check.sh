#!/bin/bash
# Lab 0.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 0.1: Provision and verify your lab VM"
check "running Ubuntu 26.04" grep -q '^VERSION_ID="26.04"' /etc/os-release
"$SHIKUMI_REPO/bin/shikumi-check" env || CHECK_FAILS=$((CHECK_FAILS + 1))
finish
