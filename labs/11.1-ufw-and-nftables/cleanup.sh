#!/bin/bash
# Lab 11.1 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

as_root nft delete table inet shikumi 2>/dev/null
as_root systemctl stop shikumi-ufw-revert.timer shikumi-nft-revert.timer 2>/dev/null
if command -v ufw >/dev/null; then
  as_root ufw delete allow 8010/tcp >/dev/null 2>&1
  as_root ufw delete allow 8011/tcp >/dev/null 2>&1
fi
pkill -u "$USER" -f 'shikumi_api.py --host 0.0.0.0 --port 801[01]' 2>/dev/null
rm -rf "$LAB_HOME/11.1"
say "Lab 11.1 cleanup done."
