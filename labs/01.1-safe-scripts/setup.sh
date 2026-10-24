#!/bin/bash
# Lab 1.1 setup: copy the lab files to ~/labs/1.1 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 1.1
