#!/bin/bash
# Build the production-shaped stack on a clean Ubuntu 26.04 VM. Safe to run again.
# Usage: sudo ./deploy.sh
set -euo pipefail
REPO="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
command -v apt-get >/dev/null || { echo "deploy.sh covers Ubuntu only"; exit 1; }
step() { printf '\n== %s\n' "$*"; }

step "Packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -q >/dev/null
apt-get install -y -q nginx apparmor-utils ufw openssl >/dev/null

step "Persistent journal"
if [[ ! -d /var/log/journal ]]; then
  mkdir -p /var/log/journal
  systemd-tmpfiles --create --prefix /var/log/journal
  systemctl restart systemd-journald
fi

step "Service user and app"
getent passwd shikumi >/dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin --user-group shikumi
install -d /opt/shikumi/bin /etc/shikumi
install -m 0755 "$REPO/app/shikumi_api.py" /opt/shikumi/bin/shikumi-api
[[ -f /etc/shikumi/shikumi-api.env ]] || install -m 0644 "$REPO/units/shikumi-api.env" /etc/shikumi/

step "AppArmor profile"
install -m 0644 "$REPO/config/apparmor/opt.shikumi.bin.shikumi-api" /etc/apparmor.d/
install -m 0644 "$REPO/config/apparmor/local/opt.shikumi.bin.shikumi-api" /etc/apparmor.d/local/
apparmor_parser -r /etc/apparmor.d/opt.shikumi.bin.shikumi-api

step "Units"
install -m 0644 "$REPO/units/shikumi-api@.service" "$REPO/units/shikumi-prune.service" \
  "$REPO/units/shikumi-prune.timer" /etc/systemd/system/
install -D -m 0644 "$REPO/units/hardening.conf" /etc/systemd/system/shikumi-api@.service.d/hardening.conf
systemctl daemon-reload
systemctl enable --now shikumi-api@8001 shikumi-api@8002 shikumi-prune.timer
systemctl restart shikumi-api@8001 shikumi-api@8002
[[ -f /var/lib/shikumi/hello.txt ]] || {
  echo "hello from /var/lib/shikumi" > /var/lib/shikumi/hello.txt
  chown shikumi:shikumi /var/lib/shikumi/hello.txt
}

step "TLS certificates"
tls=/etc/nginx/shikumi-tls
if [[ ! -f $tls/server.crt ]]; then
  install -d -m 0755 "$tls"
  work="$(mktemp -d)"
  (cd "$work" && bash "$REPO/labs/12.2-tls-and-http2/files/make-certs.sh" >/dev/null)
  install -m 0644 "$work/server.crt" "$work/ca.crt" "$tls/"
  install -m 0600 "$work/server.key" "$tls/"
  install -m 0600 "$work/ca.key" /etc/shikumi/ca.key
  rm -rf "$work"
fi

step "nginx"
install -m 0644 "$REPO/config/nginx/tls.conf" /etc/nginx/sites-available/shikumi
ln -sf /etc/nginx/sites-available/shikumi /etc/nginx/sites-enabled/shikumi
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx
systemctl reload nginx

step "Firewall"
if ! ufw status | grep -q '^Status: active'; then
  systemd-run --quiet --on-active=10min --unit shikumi-ufw-revert /usr/sbin/ufw disable
  echo "ufw undo armed for 10 minutes. Once a new SSH session works: sudo systemctl stop shikumi-ufw-revert.timer"
fi
ufw allow OpenSSH >/dev/null
ufw allow 80/tcp >/dev/null
ufw allow 443/tcp >/dev/null
ufw --force enable >/dev/null

step "Done"
echo "CA certificate for clients: $tls/ca.crt"
