#!/bin/bash

set -euo pipefail

echo "=== Iniciando limpeza de pods no cluster Kubernetes ==="

delete_failed_pods_by_reason () {
  local REASON="$1"
  echo ""
  echo "-> Deletando pods Failed com status: $REASON"

  kubectl get pods --all-namespaces --field-selector=status.phase=Failed \
    | grep "$REASON" \
    | awk '{print "kubectl delete pod -n "$1" "$2}' \
    | bash || true
}

# Pods Failed por motivo específico
delete_failed_pods_by_reason "Evicted"
delete_failed_pods_by_reason "Error"
delete_failed_pods_by_reason "ContainerStatusUnknown"
delete_failed_pods_by_reason "OOMKilled"

echo ""
echo "-> Deletando pods com status Completed 0/1"

kubectl get pods --all-namespaces --no-headers \
  | awk '$3 == "0/1" && $4 == "Completed" {print $1, $2}' \
  | while read -r NAMESPACE POD; do
      echo "Deletando Pod: $POD no namespace: $NAMESPACE"
      kubectl delete pod "$POD" -n "$NAMESPACE" || true
    done

echo ""
echo "=== Limpeza concluída com sucesso ==="
