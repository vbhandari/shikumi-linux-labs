#!/bin/bash
# Lab 11.4 setup: copy the lab files to ~/labs/11.4 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 11.4
