#!/usr/bin/env bash
# check-btp-pods.sh
set -euo pipefail

for node in $(kubectl get nodes --no-headers -o custom-columns=":metadata.name" \
  --selector='!node-role.kubernetes.io/control-plane'); do

  echo "===== $node ====="

  echo ">> Resource Summary:"
  kubectl describe node $node | grep -A 6 "Resource"

  echo ""
  echo ">> Conditions:"
  kubectl describe node $node | awk '/Conditions:/,/Allocatable:/'

  echo ""
  echo "==============================="
  echo ""

done