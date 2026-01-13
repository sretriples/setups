#!/usr/bin/env bash

kubectl get replicasets --no-headers | awk '$2 == 0 && $3 == 0 {print $1}' | while read rpst; do
  echo "Deletando ReplicaSet: $rpst"
  # kubectl delete replicaset "$rpst"
done