#!/bin/bash
# Prepare a lab VM. Ubuntu first; Fedora and Debian are alternates (untested).
# Usage: sudo bash provision.sh [--clone USER]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/vbhandari/shikumi-linux-labs.git"
CLONE_USER=""
[[ "${1:-}" == "--clone" ]] && CLONE_USER="${2:?--clone needs a user name}"

[[ $EUID -eq 0 ]] || { echo "run as root (sudo)"; exit 1; }

. /etc/os-release
case "${ID}:${ID_LIKE:-}" in
  ubuntu:*) FAMILY=ubuntu; COL=2 ;;
  debian:*) FAMILY=debian; COL=4 ;;
  fedora:*|*:*fedora*|*:*rhel*) FAMILY=fedora; COL=3 ;;
  *) echo "unsupported distro: $PRETTY_NAME"; exit 1 ;;
esac
echo "Provisioning $PRETTY_NAME as $FAMILY"

mapfile -t PKGS < <(awk -v c="$COL" '!/^#/ && NF { if ($c != "-") print $c }' "$HERE/packages.map")

if [[ $FAMILY == fedora ]]; then
  dnf -y install "${PKGS[@]}"
  systemctl enable --now firewalld
  firewall-cmd --permanent --add-service=ssh && firewall-cmd --reload
else
  # Never wait for input: no debconf or needrestart
  # prompts, keep existing config files, and keep apt
  # away from the terminal.
  export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a
  export NEEDRESTART_SUSPEND=1
  APT=(-y -o Dpkg::Use-Pty=0
    -o Dpkg::Options::=--force-confdef
    -o Dpkg::Options::=--force-confold)
  apt-get update </dev/null
  apt-get install "${APT[@]}" "${PKGS[@]}" </dev/null
  if [[ $FAMILY == ubuntu ]]; then
    # perf must match the running kernel; linux-tools-generic follows future kernels.
    apt-get install "${APT[@]}" "linux-tools-$(uname -r)" \
      </dev/null ||
      echo "note: no linux-tools for $(uname -r)"
  fi
fi

# netem (network fault injection) lives in an extra modules package on some kernels.
if ! modprobe -q sch_netem; then
  case $FAMILY in
    ubuntu) apt-get install "${APT[@]}" </dev/null \
              "linux-modules-extra-$(uname -r)" || true ;;
    fedora) dnf -y install "kernel-modules-extra-$(uname -r)" || true ;;
  esac
  modprobe -q sch_netem || echo "note: sch_netem is unavailable; Lab 11.4 will not work"
fi

# Keep the journal across reboots (Lab 5.2).
mkdir -p /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal
systemctl restart systemd-journald

# Log access (Lab 0.1 journalctl, Lab 5.2 /var/log/syslog). Multipass's
# ubuntu user is in adm already; cloud and hand-made users often are not.
LAB_USER="${CLONE_USER:-${SUDO_USER:-}}"
getent group adm >/dev/null || groupadd --system adm
if [[ -n $LAB_USER && $LAB_USER != root ]] && getent passwd "$LAB_USER" >/dev/null; then
  for g in adm systemd-journal; do
    if getent group "$g" >/dev/null && ! id -nG "$LAB_USER" | tr ' ' '\n' | grep -qx "$g"; then
      usermod -aG "$g" "$LAB_USER"
      echo "added $LAB_USER to $g; log out and back in to use it"
    fi
  done
fi

if [[ -n $CLONE_USER ]]; then
  home="$(getent passwd "$CLONE_USER" | cut -d: -f6)"
  if [[ -d "$home/shikumi-linux-labs/.git" ]]; then
    runuser -u "$CLONE_USER" -- git -C "$home/shikumi-linux-labs" pull --ff-only
  else
    runuser -u "$CLONE_USER" -- git clone "$REPO_URL" "$home/shikumi-linux-labs"
  fi
  runuser -u "$CLONE_USER" -- mkdir -p "$home/labs"
fi

echo "Done. Next: ~/shikumi-linux-labs/bin/shikumi-check env"
