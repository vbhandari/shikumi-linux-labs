#!/bin/bash
# Lab 1.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 1.1: Make a deploy script fail loudly"
W="$LAB_HOME/1.1"
script="$W/deploy.sh"
check "shellcheck is clean" shellcheck "$script"
t="$(mktemp -d)"
cp -R "$(lab_dir 1.1)/files/." "$t/"
cp "$script" "$t/deploy.sh"
if (cd "$t" && bash ./deploy.sh v3) >/dev/null 2>&1; then bad "a missing release must exit non-zero"; else ok "a missing release exits non-zero"; fi
check "important.txt survives a failed deploy" test -f "$t/site/current/important.txt"
check "a good release exits 0" bash -c "cd '$t' && bash ./deploy.sh v2"
check "a good release deploys index.html" test -f "$t/site/current/index.html"
rm -rf "$t"
finish
