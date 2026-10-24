#!/bin/bash
# Lab 12.1 setup: copy the lab files to ~/labs/12.1 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 12.1
