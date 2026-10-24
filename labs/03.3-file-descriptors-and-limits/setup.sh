#!/bin/bash
# Lab 3.3 setup: copy the lab files to ~/labs/3.3 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 3.3
