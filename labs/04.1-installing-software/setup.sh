#!/bin/bash
# Lab 4.1 setup: copy the lab files to ~/labs/4.1 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 4.1
if dpkg-query -W -f='${Status}' nginx 2>/dev/null | grep -q 'install ok installed' || rpm -q nginx >/dev/null 2>&1; then
  note "nginx is already installed, so step 2 will not install anything and port 80 may be taken."
  note "For the lab as written, remove it first: sudo apt purge -y nginx nginx-common && sudo apt autoremove -y"
fi
