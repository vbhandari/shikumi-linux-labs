#!/bin/bash
# Lab 5.3 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

d=/etc/systemd/system/shikumi-api.service.d
as_root rm -f "$d/port80.conf"
[[ -f /etc/shikumi/shikumi-api.env ]] && as_root sed -i '/^SHIKUMI_CACHE/d' /etc/shikumi/shikumi-api.env
as_root systemctl daemon-reload
as_root systemctl try-restart shikumi-api
rm -rf "$LAB_HOME/5.3"
say "Lab 5.3 cleanup done."
