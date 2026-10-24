#!/bin/bash
# Lab 10.1 setup: copy the lab files to ~/labs/10.1 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 10.1
cp "$SHIKUMI_REPO/app/closewait.py" "$LAB_HOME/10.1/closewait.py"
