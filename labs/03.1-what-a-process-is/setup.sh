#!/bin/bash
# Lab 3.1 setup: copy the lab files to ~/labs/3.1 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 3.1
