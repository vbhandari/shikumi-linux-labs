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
check "inet shikumi table drops 8011" bash -c "sudo nft list table inet shikumi 2>/dev/null | grep -q 'tcp dport 8011 .*drop'"
finish
