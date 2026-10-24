#!/bin/bash
# Lab 15.1 setup: copy the lab files to ~/labs/15.1 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 15.1
