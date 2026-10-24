#!/bin/bash
# Lab 14.3 setup: copy the lab files to ~/labs/14.3 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 14.3
need_cmd perf
