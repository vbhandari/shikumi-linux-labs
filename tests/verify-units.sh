#!/bin/bash
# Verify the unit files the way systemd will load them, drop-ins included.
# Needs /opt/shikumi/bin/shikumi-api to exist (CI installs it); run from the repo root.
set -euo pipefail
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cp units/shikumi-api.service units/shikumi-prune.service units/shikumi-prune.timer "$work/"
cp units/shikumi-api@.service "$work/shikumi-api@8001.service"
# A unit with the hardening drop-in merged in, as systemd would see it.
cat units/shikumi-api.service units/hardening.conf > "$work/shikumi-api-hardened.service"
cat units/shikumi-api@.service units/hardening.conf | sed 's/%i/8002/g' > "$work/shikumi-api-hardened@8002.service"

status=0
for u in "$work"/*.service "$work"/*.timer; do
  if out="$(systemd-analyze verify "$u" 2>&1)" && [[ -z "$out" ]]; then
    echo "ok    $(basename "$u")"
  else
    echo "FAIL  $(basename "$u")"; status=1
    while IFS= read -r line; do echo "      $line"; done <<<"$out"
  fi
done

for u in shikumi-api.service shikumi-api-hardened.service; do
  score="$(systemd-analyze security --offline=true "$work/$u" 2>/dev/null | awk '/Overall exposure level/ {for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+\.[0-9]+$/) print $i, $(i + 1)}')"
  echo "score $u: ${score:-unavailable}"
done
exit "$status"
