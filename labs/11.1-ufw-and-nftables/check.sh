#!/bin/bash
# Lab 11.1 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 11.1: ufw, and the nftables underneath"
st="$(sudo ufw status 2>/dev/null)"
check "ufw is active" grep -q '^Status: active' <<<"$st"
check "OpenSSH allowed" grep -q '^OpenSSH .*ALLOW' <<<"$st"
check "8010/tcp allowed" grep -q '^8010/tcp .*ALLOW' <<<"$st"
check "8011/tcp allowed" grep -q '^8011/tcp .*ALLOW' <<<"$st"
if systemctl is-active --quiet shikumi-ufw-revert.timer; then bad "ufw undo timer stopped (sudo systemctl stop shikumi-ufw-revert.timer)"; else ok "ufw undo timer stopped"; fi
check "ufw chains in nftables" bash -c "sudo nft list ruleset | grep -q 'chain ufw-user-input'"
nftu=shikumi-nft-revert
fired="$(systemctl show -p LastTriggerUSec --value "$nftu.timer" 2>/dev/null)"
if as_root nft list table inet shikumi >/dev/null 2>&1; then
  check "inet shikumi table drops 8011" bash -c "sudo nft list table inet shikumi | grep -q 'tcp dport 8011 .*drop'"
elif systemctl is-failed --quiet "$nftu.service"; then
  bad "inet shikumi table: its undo failed, so it was never loaded (run step 5)"
elif [[ "$fired" =~ [0-9] ]] || as_root journalctl -b -q -u "$nftu.service" 2>/dev/null | grep -q .; then
  note "the inet shikumi table is gone: its 5-minute undo fired, by design"
  note "to see the drop again: sudo nft -f $SHIKUMI_REPO/config/nftables/shikumi.nft"
  ok "inet shikumi table was loaded, then removed by its undo"
else
  bad "inet shikumi table drops 8011 (not loaded: run step 5)"
fi
finish
