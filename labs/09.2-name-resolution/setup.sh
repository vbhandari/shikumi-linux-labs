#!/bin/bash
# Lab 9.2 setup: copy the lab files to ~/labs/9.2 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 9.2
