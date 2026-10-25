#!/bin/bash
# Lab 13.4 cleanup: undo this lab's changes; safe to run more than once.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

podman rm -f shikumi-alpine >/dev/null 2>&1
podman rmi docker.io/library/alpine:3.24 >/dev/null 2>&1
rm -rf "$LAB_HOME/13.4"
say "Lab 13.4 cleanup done."
