#!/bin/bash
# Lab 14.2 setup: copy the lab files to ~/labs/14.2 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 14.2
cp "$SHIKUMI_REPO/app/deadlock.py" "$LAB_HOME/14.2/deadlock.py"
