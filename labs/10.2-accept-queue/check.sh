#!/bin/bash
# Lab 10.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 10.2: Fill the accept queue"
W="$LAB_HOME/10.2"
check "backlog8.txt has results" grep -q '^requests=' "$W/backlog8.txt"
check "backlog64.txt has results" grep -q '^requests=' "$W/backlog64.txt"
overflows() { nstat -az TcpExtListenOverflows | awk '/ListenOverflows/ {print $2}'; }
before="$(overflows)"
python3 "$SHIKUMI_REPO/app/acceptq.py" --backlog 8 --port 8310 >/dev/null & a=$!
sleep 1
python3 - <<'PY' & c=$!
import socket, time
socks = []
for _ in range(30):
    s = socket.socket()
    s.setblocking(False)
    s.connect_ex(("127.0.0.1", 8310))
    socks.append(s)
time.sleep(3)
PY
sleep 2
read -r recvq sendq < <(ss -Hlnt 'sport = :8310' | awk '{print $2, $3}')
wait "$c"; kill "$a"
check "Send-Q is the backlog (${sendq:-?})" test "${sendq:-0}" = 8
check "Recv-Q filled to backlog + 1 (${recvq:-?})" test "${recvq:-0}" = 9
check "ListenOverflows rose ($before -> $(overflows))" test "$(overflows)" -gt "${before:-0}"
finish
