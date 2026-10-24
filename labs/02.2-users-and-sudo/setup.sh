#!/bin/bash
# Lab 2.2 setup: copy the lab files to ~/labs/2.2 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 2.2
