#!/bin/bash
# Verify the unit files the way systemd will load them, drop-ins included.
# Needs /opt/shikumi/bin/shikumi-api and the shikumi user (CI installs both); run from the repo root.
set -euo pipefail
[[ -x /opt/shikumi/bin/shikumi-api ]] || { echo "FAIL  /opt/shikumi/bin/shikumi-api is missing"; exit 1; }
getent passwd shikumi >/dev/null || { echo "FAIL  user shikumi is missing"; exit 1; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cp units/shikumi-api.service units/shikumi-prune.service units/shikumi-prune.timer "$work/"
cp units/shikumi-api@.service "$work/shikumi-api@8001.service"
# A unit with the hardening drop-in merged in, as systemd would see it.
cat units/shikumi-api.service units/hardening.conf > "$work/shikumi-api-hardened.service"
cat units/shikumi-api@.service units/hardening.conf | sed 's/%i/8002/g' > "$work/shikumi-api-hardened@8002.service"

# verify also loads the host's units that ours pull in (sysinit.target,
# timers.target, ...). Their warnings are not ours: show them, but only lines
# about our own units, or a non-zero exit for our unit, count as failures.
status=0
for u in "$work"/*.service "$work"/*.timer; do
  name="$(basename "$u")"
  rc=0
  out="$(systemd-analyze verify --recursive-errors=no --man=no "$u" 2>&1)" || rc=$?
  ours="$(grep -F -e "$work/" -e "$name" <<<"$out" || true)"
  host="$(grep -v -F -e "$work/" -e "$name" <<<"$out" | grep . || true)"
  if [[ $rc -eq 0 && -z "$ours" ]]; then
    echo "ok    $name"
  else
    echo "FAIL  $name"; status=1
    while IFS= read -r line; do echo "      $line"; done <<<"${ours:-exit status $rc}"
  fi
  [[ -z "$host" ]] || echo "      ($(wc -l <<<"$host") warning(s) from host units ignored, e.g. ${host%%$'\n'*})"
done

for u in shikumi-api.service shikumi-api-hardened.service; do
  score="$(systemd-analyze security --offline=true "$work/$u" 2>/dev/null | awk '/Overall exposure level/ {for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+\.[0-9]+$/) print $i, $(i + 1)}')"
  echo "score $u: ${score:-unavailable}"
done
exit "$status"
