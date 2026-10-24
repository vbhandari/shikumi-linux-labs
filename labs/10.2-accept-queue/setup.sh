#!/bin/bash
# Lab 10.2 setup: copy the lab files to ~/labs/10.2 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 10.2
