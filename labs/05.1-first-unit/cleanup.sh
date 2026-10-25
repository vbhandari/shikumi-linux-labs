#!/bin/bash
# Lab 5.1 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

if [[ -f /etc/systemd/system/shikumi-api.service.d/limits.conf ]]; then
  as_root rm -f /etc/systemd/system/shikumi-api.service.d/limits.conf
  as_root systemctl daemon-reload
  as_root systemctl try-restart shikumi-api
fi
rm -rf "$LAB_HOME/5.1"
say "Lab 5.1 cleanup done."
