#!/bin/bash
# Lab 8.4 setup: copy the lab files to ~/labs/8.4 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 8.4
