#!/bin/bash
# Lab 6.1 setup: copy the lab files to ~/labs/6.1 and check prerequisites.
set -euo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

lab_setup 6.1
need_cmd aa-genprof aa-status apparmor_parser
ensure_shikumi_user
as_root install -d -o shikumi -g shikumi /var/lib/shikumi
if ! as_root test -f /var/lib/shikumi/hello.txt; then
  echo "hello from /var/lib/shikumi" | as_root tee /var/lib/shikumi/hello.txt >/dev/null
  as_root chown shikumi:shikumi /var/lib/shikumi/hello.txt
fi
say "/data?name=hello.txt reads /var/lib/shikumi/hello.txt"
