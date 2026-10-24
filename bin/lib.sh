#!/bin/bash
# Shared helpers for lab scripts. Source it; do not run it.
# shellcheck disable=SC2034  # variables are used by the scripts that source this file

SHIKUMI_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAB_HOME="${LAB_HOME:-$HOME/labs}"
CHECK_FAILS=0

# ubuntu | debian | fedora | unknown
distro_family() {
  local id="" like=""
  if [[ -r /etc/os-release ]]; then
    id="$(. /etc/os-release && echo "${ID:-}")"
    like="$(. /etc/os-release && echo "${ID_LIKE:-}")"
  fi
  case "$id" in
    ubuntu) echo ubuntu ;;
    debian) echo debian ;;
    fedora|rhel|centos|rocky|almalinux) echo fedora ;;
    *) case "$like" in
         *ubuntu*) echo ubuntu ;;
         *debian*) echo debian ;;
         *fedora*|*rhel*) echo fedora ;;
         *) echo unknown ;;
       esac ;;
  esac
}

as_root() {
  if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi
}

say()  { printf '%s\n' "$*"; }
ok()   { printf '  PASS  %s\n' "$*"; }
bad()  { printf '  FAIL  %s\n' "$*"; CHECK_FAILS=$((CHECK_FAILS + 1)); }
note() { printf '  NOTE  %s\n' "$*"; }

# check "description" command [args...]: run quietly, report PASS or FAIL.
check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else bad "$desc"; fi
}

need_cmd() {
  local c
  for c in "$@"; do
    check "command available: $c" command -v "$c"
  done
}

# Fail the calling script if any check failed.
finish() {
  if [[ $CHECK_FAILS -eq 0 ]]; then
    say "All checks passed."
  else
    say "$CHECK_FAILS check(s) failed."
    exit 1
  fi
}

# lab_setup ID: copy the lab's files/ into ~/labs/ID (step 0 of every lab).
lab_setup() {
  local id="$1" src
  src="$(lab_dir "$id")/files"
  mkdir -p "$LAB_HOME/$id"
  if [[ -d "$src" ]]; then
    cp -R "$src/." "$LAB_HOME/$id/"
  fi
  say "Lab $id files are in $LAB_HOME/$id"
}

# lab_dir 5.1 -> .../labs/05.1-slug
lab_dir() {
  local d padded
  printf -v padded '%02d.%s' "${1%%.*}" "${1#*.}"
  for d in "$SHIKUMI_REPO"/labs/"$padded"-*; do
    [[ -d "$d" ]] && { echo "$d"; return 0; }
  done
  return 1
}

# Prerequisites shared by several labs.
ensure_shikumi_user() {
  getent passwd shikumi >/dev/null || as_root useradd --system --no-create-home \
    --shell /usr/sbin/nologin --user-group shikumi
}

ensure_app_installed() {
  ensure_shikumi_user
  as_root install -d /opt/shikumi/bin /etc/shikumi
  as_root install -m 0755 "$SHIKUMI_REPO/app/shikumi_api.py" /opt/shikumi/bin/shikumi-api
  [[ -f /etc/shikumi/shikumi-api.env ]] || \
    as_root install -m 0644 "$SHIKUMI_REPO/units/shikumi-api.env" /etc/shikumi/shikumi-api.env
}

main_pid() {
  systemctl show -p MainPID --value "$1"
}

uplink() {
  ip route show default | awk '{print $5; exit}'
}

http_status() {
  curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$@"
}

# shikumi-unshare is a copy of unshare whose own AppArmor profile may create
# user namespaces (Lab 13.1). Lab 13.3 reinstalls it if it is gone.
ensure_shikumi_unshare() {
  [[ -x /usr/local/bin/shikumi-unshare ]] || \
    as_root install -m 0755 "$(command -v unshare)" /usr/local/bin/shikumi-unshare
  if [[ -d /sys/kernel/security/apparmor ]] && command -v apparmor_parser >/dev/null; then
    as_root install -m 0644 "$SHIKUMI_REPO/config/apparmor/shikumi-unshare" /etc/apparmor.d/shikumi-unshare
    as_root apparmor_parser -r /etc/apparmor.d/shikumi-unshare
  fi
}

remove_shikumi_unshare() {
  if [[ -f /etc/apparmor.d/shikumi-unshare ]]; then
    as_root apparmor_parser -R /etc/apparmor.d/shikumi-unshare 2>/dev/null
    as_root rm -f /etc/apparmor.d/shikumi-unshare
  fi
  as_root rm -f /usr/local/bin/shikumi-unshare
}
