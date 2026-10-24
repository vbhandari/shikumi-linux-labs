#!/bin/bash
# Lab 13.1 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

if [[ -f /etc/apparmor.d/shikumi-unshare ]]; then
  as_root apparmor_parser -R /etc/apparmor.d/shikumi-unshare 2>/dev/null
  as_root rm -f /etc/apparmor.d/shikumi-unshare
fi
as_root rm -f /usr/local/bin/shikumi-unshare
v="$(sysctl -n kernel.apparmor_restrict_unprivileged_userns 2>/dev/null || echo absent)"
if [[ "$v" == 1 || "$v" == absent ]]; then
  ok "kernel.apparmor_restrict_unprivileged_userns = $v"
else
  bad "kernel.apparmor_restrict_unprivileged_userns is $v, expected 1. Restore it: sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=1"
  exit 1
fi
say "Lab 13.1 cleanup done."
