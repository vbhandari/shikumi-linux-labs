#!/bin/bash
# Lab 13.4 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 13.4: What Podman adds"
check "shikumi-alpine is running" test "$(podman inspect -f '{{.State.Running}}' shikumi-alpine 2>/dev/null)" = true
check "subuid entry for $USER" grep -q "^$USER:" /etc/subuid
pid="$(podman inspect -f '{{.State.Pid}}' shikumi-alpine 2>/dev/null)"
check "own network namespace" test "$(readlink "/proc/${pid:-0}/ns/net" 2>/dev/null)" != "$(readlink /proc/self/ns/net)"
check "seccomp filter active" grep -q '^Seccomp:[[:space:]]*2' "/proc/${pid:-0}/status"
check "reduced capabilities" bash -c "! grep -q '^CapEff:[[:space:]]*000001ffffffffff' /proc/${pid:-0}/status"
finish
