#!/bin/bash
# Lab 2.3 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 2.3: A shared release directory, and why port 80 is refused"
check "/srv/shikumi is 2770 root:deploy" test "$(stat -c '%a %U %G' /srv/shikumi 2>/dev/null)" = "2770 root deploy"
acl="$(getfacl -p /srv/shikumi 2>/dev/null)"
check "ACL: shikumi may read" grep -qx 'user:shikumi:r-x' <<<"$acl"
check "default ACL: shikumi may read new files" grep -qx 'default:user:shikumi:r-x' <<<"$acl"
check "deployer can create files" as_root sudo -u deployer bash -c ': > /srv/shikumi/.check && rm /srv/shikumi/.check'
if as_root sudo -u shikumi touch /srv/shikumi/.nope 2>/dev/null; then as_root rm -f /srv/shikumi/.nope; bad "shikumi cannot create files"; else ok "shikumi cannot create files"; fi
out="$(timeout 5 python3 "$SHIKUMI_REPO/app/shikumi_api.py" --port 80 2>&1)"
check "port 80 is refused to a normal user" grep -q 'Errno 13' <<<"$out"
finish
