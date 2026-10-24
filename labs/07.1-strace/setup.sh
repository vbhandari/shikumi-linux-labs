#!/bin/bash
# Lab 7.1 setup: copy the lab files to ~/labs/7.1 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 7.1
