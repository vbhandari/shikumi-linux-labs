#!/bin/bash
# Create the lab VM with Multipass (run on your laptop, from the repo root).
set -euo pipefail
NAME="${1:-shikumi}"
multipass launch 26.04 --name "$NAME" --cpus 2 --memory 4G --disk 20G \
  --cloud-init "$(dirname "$0")/cloud-init.yaml" --timeout 1200
multipass exec "$NAME" -- cloud-init status --wait
multipass info "$NAME"
echo "Connect with: multipass shell $NAME"
