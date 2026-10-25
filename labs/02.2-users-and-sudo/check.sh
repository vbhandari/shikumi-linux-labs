#!/bin/bash
# Lab 2.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 2.2: Users, groups and an exact-command sudo rule"
uid="$(id -u shikumi 2>/dev/null)"
check "shikumi is a system user (uid ${uid:-none})" test "${uid:-99999}" -lt 1000
check "shikumi has no login shell" bash -c "getent passwd shikumi | grep -q ':/usr/sbin/nologin$'"
check "deployer is in deploy" bash -c "id -nG deployer | tr ' ' '\n' | grep -qx deploy"
f=/etc/sudoers.d/90-shikumi-deploy
# /etc/sudoers.d is 0750 on Ubuntu 26.04, so only root can stat the rule.
check "rule installed as 0440 root:root" test "$(as_root stat -c '%a %U %G' "$f" 2>/dev/null)" = "440 root root"
check "sudoers passes visudo -c" as_root visudo -c
check "deployer may restart shikumi-api" as_root sudo -l -U deployer /usr/bin/systemctl restart shikumi-api.service
if as_root sudo -l -U deployer /usr/bin/systemctl stop shikumi-api.service >/dev/null 2>&1; then bad "deployer may not stop shikumi-api"; else ok "deployer may not stop shikumi-api"; fi
finish
