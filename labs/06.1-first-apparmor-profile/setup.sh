#!/bin/bash
# Lab 6.1 setup: copy the lab files to ~/labs/6.1 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 6.1
need_cmd aa-genprof aa-status apparmor_parser
