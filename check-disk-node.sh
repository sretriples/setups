#!/usr/bin/env bash
# check-btp-pods.sh
set -euo pipefail
IFS=$'\n\t'

OUTPUT_FILE="btp_pods_report.txt"
LOG_OUTPUT_DIR="pod_logs"
mkdir -p "$LOG_OUTPUT_DIR"

: > "$OUTPUT_FILE"  # Limpa o arquivo de saída

command -v kubectl >/dev/null 2>&1 || { echo "ERRO: kubectl não encontrado no PATH"; exit 2; }

USE_JQ=false
if command -v jq >/dev/null 2>&1; then
  USE_JQ=true
fi

echo "====== Análise de Pods em Namespaces 'btp-*' com status anormal ======"
echo "====== Análise de Pods em Namespaces 'btp-*' com status anormal ======" >> "$OUTPUT_FILE"

namespaces=()
while IFS= read -r ns; do
  ns=${ns#namespace/}
  [[ "$ns" =~ ^btp- ]] && namespaces+=("$ns")
done < <(kubectl get ns -o name)

if [ ${#namespaces[@]} -eq 0 ]; then
  echo "Nenhum namespace com prefixo 'btp-' encontrado."
  echo "Nenhum namespace com prefixo 'btp-' encontrado." >> "$OUTPUT_FILE"
  exit 0
fi

for ns in "${namespaces[@]}"; do
  echo
  echo "Namespace: $ns"
  echo "------------------------------------------------------------"
  {
    echo
    echo "Namespace: $ns"
    echo "------------------------------------------------------------"
  } >> "$OUTPUT_FILE"

  if $USE_JQ; then
    pods_json=$(kubectl get pods -n "$ns" -o json)

    echo "$pods_json" | jq -r '
      .items[]
      | select(
          .status.phase != "Running" and .status.phase != "Succeeded"
          or (
            .status.containerStatuses != null and
            (
              [.status.containerStatuses[].state.waiting.reason // ""]
              | map(test("CrashLoopBackOff|ImagePullBackOff|ErrImagePull|CreateContainerConfigError"))
              | any
            )
          )
        )
      | [.metadata.name, .status.phase] | @tsv
    ' | while IFS=$'\t' read -r pod phase; do
        echo "  - $pod (status: $phase)"
        echo "  - $pod (status: $phase)" >> "$OUTPUT_FILE"

        # Salvar describe
        {
          echo
          echo "===== kubectl describe pod $pod (namespace: $ns) ====="
          kubectl describe pod "$pod" -n "$ns"
        } >> "$OUTPUT_FILE" 2>/dev/null || echo "    ERRO ao descrever pod $pod" >> "$OUTPUT_FILE"

        # Salvar logs anteriores
        log_file="${LOG_OUTPUT_DIR}/logs_${ns}_${pod}.txt"
        echo "    -> Salvando kubectl logs --previous em: $log_file"
        echo "===== kubectl logs --previous do pod $pod (namespace: $ns) =====" > "$log_file"
        kubectl logs "$pod" -n "$ns" --previous >> "$log_file" 2>>"$log_file" || echo "    ERRO ao obter logs anteriores do pod $pod" >> "$log_file"
      done

  else
    pods=$(kubectl get pods -n "$ns" --no-headers -o custom-columns=":metadata.name")
    found_problem=false

    for pod in $pods; do
      phase=$(kubectl get pod "$pod" -n "$ns" -o jsonpath='{.status.phase}')
      reasons=$(kubectl get pod "$pod" -n "$ns" -o jsonpath='{.status.containerStatuses[*].state.waiting.reason}' 2>/dev/null || echo "")

      if [[ "$phase" != "Running" && "$phase" != "Succeeded" ]] || [[ "$reasons" =~ (CrashLoopBackOff|ImagePullBackOff|ErrImagePull|CreateContainerConfigError) ]]; then
        found_problem=true
        echo "  - $pod (status: $phase, reason: $reasons)"
        echo "  - $pod (status: $phase, reason: $reasons)" >> "$OUTPUT_FILE"

        # Salvar describe
        {
          echo
          echo "===== kubectl describe pod $pod (namespace: $ns) ====="
          kubectl describe pod "$pod" -n "$ns"
        } >> "$OUTPUT_FILE" 2>/dev/null || echo "    ERRO ao descrever pod $pod" >> "$OUTPUT_FILE"

        # Salvar logs anteriores
        log_file="${LOG_OUTPUT_DIR}/logs_${ns}_${pod}.txt"
        echo "    -> Salvando kubectl logs --previous em: $log_file"
        echo "===== kubectl logs --previous do pod $pod (namespace: $ns) =====" > "$log_file"
        kubectl logs "$pod" -n "$ns" --previous >> "$log_file" 2>>"$log_file" || echo "    ERRO ao obter logs anteriores do pod $pod" >> "$log_file"
      fi
    done

    if ! $found_problem; then
      echo "  Nenhum pod com problemas detectado."
      echo "  Nenhum pod com problemas detectado." >> "$OUTPUT_FILE"
    fi
  fi
done

echo
echo "✅ Análise concluída."
echo "📄 Relatório: $OUTPUT_FILE"
echo "📂 Logs anteriores salvos em: $LOG_OUTPUT_DIR/"