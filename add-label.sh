#!/bin/bash
# Adicione os namespaces e rótulos desejados
namespaces=(
  "kube-system"

)

labels=(
  "pod-security.kubernetes.io/audit=privileged"
  "pod-security.kubernetes.io/audit-version=latest"
  "pod-security.kubernetes.io/enforce=privileged"
  "pod-security.kubernetes.io/enforce-version=latest"
  "pod-security.kubernetes.io/warn=privileged"
  "pod-security.kubernetes.io/warn-version=latest"
)

for ns in "${namespaces[@]}"; do
  echo "Adicionando rótulos no namespace: $ns"
  for label in "${labels[@]}"; do
    kubectl label namespace "$ns" "$label" --overwrite
  done
done