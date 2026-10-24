#!/bin/bash
# Start one hidden problem as a transient unit.
# Usage: sudo ./mystery.sh | sudo ./mystery.sh --reveal | sudo ./mystery.sh --stop
set -euo pipefail
unit=shikumi-mystery
answer=/run/shikumi-mystery.answer
data=/var/tmp/shikumi-mystery.dat

[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
case "${1:-start}" in
  --reveal) cat "$answer"; exit 0 ;;
  --stop) systemctl stop "$unit" 2>/dev/null || true
          systemctl reset-failed "$unit" 2>/dev/null || true
          rm -f "$answer" "$data"; echo "stopped"; exit 0 ;;
esac
if systemctl is-active --quiet "$unit"; then echo "already running; use --stop first"; exit 1; fi

kinds=(cpu memory io)
kind="${kinds[RANDOM % 3]}"
case "$kind" in
  cpu) cmd=(bash -c 'for _ in $(seq "$(nproc)"); do (while :; do :; done) & done; wait') ;;
  memory)
    mb=$(( $(awk '/MemAvailable/ {print $2}' /proc/meminfo) * 85 / 100 / 1024 ))
    cmd=(python3 -c "import time; held = [bytearray(1 << 20) for _ in range($mb)]; time.sleep(3600)") ;;
  io) cmd=(fio --name=worker --filename="$data" --size=512M --rw=randwrite --bs=4k --direct=1
           --ioengine=psync --time_based --runtime=3600 --output=/dev/null) ;;
esac
systemd-run --quiet --unit "$unit" -p RuntimeMaxSec=1h "${cmd[@]}"
install -m 0600 /dev/null "$answer"
echo "$kind" > "$answer"
echo "A problem is running. Find it, write cpu, memory or io into answer.txt, then run check."
