#!/bin/bash
# Inject one fault into the Lab 15.1 stack, or undo them all.
# Usage: sudo ./break.sh N   (N = 1..7)    sudo ./break.sh --undo
# Spoiler: the code below shows what each drill breaks. Read it after the drills.
set -euo pipefail
REPO="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
STATE=/run/shikumi-drill
DROPIN=/etc/systemd/system/shikumi-api@8001.service.d
DROPIN2=/etc/systemd/system/shikumi-api@8002.service.d
DRILL_FS=/var/log/shikumi-drill
[[ "${1:-}" == -h || "${1:-}" == --help ]] && { echo "usage: sudo $0 N (1..7) | --undo"; exit 0; }
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
mkdir -p "$STATE"

reload() { systemctl daemon-reload; systemctl restart "$@"; }

fault_1() {
  install -D -m 0644 /dev/stdin "$DROPIN/drill-1.conf" <<<$'[Service]\nLimitNOFILE=64'
  reload shikumi-api@8001
  sleep 1; curl -s -o /dev/null 'http://127.0.0.1:8001/files?n=100' || true
}
fault_2() {
  install -m 0755 "$REPO/app/closewait.py" "$STATE/worker-2.py"
  systemd-run --quiet --unit shikumi-drill-2a -p DynamicUser=yes -p StandardOutput=null python3 "$STATE/worker-2.py"
  systemd-run --quiet --unit shikumi-drill-2b -p DynamicUser=yes \
    bash -c 'while :; do curl -s -m 1 -o /dev/null http://127.0.0.1:8200/; sleep 0.2; done'
  # Wait for the first leaked socket, so a check run straight away already fails.
  for _ in {1..50}; do [[ -n "$(ss -Htan state close-wait)" ]] && break; sleep 0.1; done
}
fault_3() {
  fallocate -l 64M /var/tmp/shikumi-drill.img
  mkfs.ext4 -q -F /var/tmp/shikumi-drill.img
  mkdir -p "$DRILL_FS"
  mount -o loop /var/tmp/shikumi-drill.img "$DRILL_FS"
  systemd-run --quiet --unit shikumi-drill-3 python3 -c "
import os, time
path = '$DRILL_FS/app.log'
f = open(path, 'ab', buffering=0)
try:
    while True:
        f.write(b'x' * 65536)
except OSError:
    pass
os.unlink(path)
time.sleep(86400)"
}
fault_4() {
  install -d -m 0755 /srv/shikumi-drill-data
  echo "drill data" > /srv/shikumi-drill-data/hello.txt
  install -D -m 0644 /dev/stdin "$DROPIN2/drill-4.conf" <<<$'[Service]\nEnvironment=SHIKUMI_DATA_DIR=/srv/shikumi-drill-data'
  reload shikumi-api@8002
}
fault_5() {
  install -D -m 0644 /dev/stdin "$DROPIN/drill-5.conf" <<<$'[Service]\nMemoryMax=60M\nMemorySwapMax=0'
  reload shikumi-api@8001
  sleep 1; curl -s -o /dev/null -m 5 'http://127.0.0.1:8001/alloc?mb=80' || true
}
fault_6() {
  install -m 0755 "$REPO/app/loadgen.py" "$STATE/client-6.py"
  systemd-run --quiet --unit shikumi-drill-6 -p DynamicUser=yes \
    bash -c "while :; do python3 $STATE/client-6.py 'http://127.0.0.1:8001/checksum?kb=1024' -c 4 -n 200 >/dev/null; done"
}
fault_7() {
  tc qdisc add dev lo root netem delay 300ms
}

undo() {
  rm -f "$DROPIN"/drill-*.conf "$DROPIN2"/drill-*.conf
  systemctl daemon-reload
  for u in shikumi-drill-2a shikumi-drill-2b shikumi-drill-3 shikumi-drill-6; do
    systemctl stop "$u" 2>/dev/null || true
    systemctl reset-failed "$u" 2>/dev/null || true
  done
  if findmnt "$DRILL_FS" >/dev/null; then umount "$DRILL_FS"; fi
  rm -rf "$DRILL_FS" /var/tmp/shikumi-drill.img /srv/shikumi-drill-data
  tc qdisc del dev lo root 2>/dev/null || true
  systemctl restart shikumi-api@8001 shikumi-api@8002
  rm -rf "$STATE"
  echo "all drills undone"
}

case "${1:-}" in
  --undo) undo ;;
  [1-7])
    [[ -e "$STATE/$1" ]] && { echo "fault $1 is already injected"; exit 1; }
    "fault_$1"
    touch "$STATE/$1"
    echo "fault $1 injected. Find it, fix it, then run: ~/shikumi-linux-labs/bin/shikumi-check lab 15.2"
    ;;
  *) echo "usage: sudo $0 N (1..7) | --undo"; exit 2 ;;
esac
