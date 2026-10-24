#!/bin/bash
# Lab 10.3 setup: copy the lab files to ~/labs/10.3 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 10.3
