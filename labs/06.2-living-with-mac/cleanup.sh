#!/bin/bash
# Lab 6.2 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

if [[ -f /etc/systemd/system/shikumi-api@.service.d/cache.conf ]]; then
  as_root rm -f /etc/systemd/system/shikumi-api@.service.d/cache.conf
  as_root systemctl daemon-reload
  as_root systemctl try-restart shikumi-api@8001 shikumi-api@8002
fi
rm -rf "$LAB_HOME/6.2"
say "Lab 6.2 cleanup done."
