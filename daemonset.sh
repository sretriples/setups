#!/bin/bash
#
# Script para atualizar certificado Harbor em nodes Photon OS de cluster EKS
# Autor: ChatGPT (GPT-5)
# Versão: 1.1 (com integração kubectl)

# ==============================
# 🔧 CONFIGURAÇÕES
# ==============================

# Usuário SSH nos nodes
USER="capv"

# IP e hostname do Harbor
HARBOR_IP="10.10.10.10"
HARBOR_HOST="harbor"

# Caminho do certificado no node remoto
REMOTE_CERT_PATH="/etc/ssl/certs/harbor-ca.crt"

# Conteúdo do certificado (substitua pelo real)
read -r -d '' CERT_CONTENT <<'EOF'
-----BEGIN CERTIFICATE-----
# Cole aqui o conteúdo completo do certificado Harbor
-----END CERTIFICATE-----
EOF

# ==============================
# 📦 OBTENDO OS NODES VIA KUBECTL
# ==============================

echo "🔍 Obtendo lista de nodes via kubectl..."

# Verifica se kubectl está configurado e acessível
if ! command -v kubectl >/dev/null 2>&1; then
  echo "❌ ERRO: kubectl não encontrado no PATH. Instale ou configure o KUBECONFIG."
  exit 1
fi

# Captura os IPs internos (coluna 6 normalmente)
NODE_IPS=$(kubectl get nodes -o wide --no-headers | awk '{print $6}')

if [ -z "$NODE_IPS" ]; then
  echo "❌ Nenhum node encontrado! Verifique se você está conectado ao cluster correto."
  exit 1
fi

echo "✅ Nodes detectados:"
echo "$NODE_IPS"
echo

# ==============================
# ⚙️ FUNÇÃO PARA EXECUTAR REMOTAMENTE
# ==============================

update_node() {
  local node_ip="$1"
  echo "🔹 Conectando ao node ${node_ip}..."

  ssh -o StrictHostKeyChecking=no ${USER}@${node_ip} "sudo bash -s" <<EOF
# Cria diretório de certificados se não existir
mkdir -p /etc/ssl/certs

# Cria ou substitui o certificado Harbor
cat > ${REMOTE_CERT_PATH} <<'EOCERT'
${CERT_CONTENT}
EOCERT

# Atualiza o store de certificados do sistema (Photon OS)
if command -v update-ca-certificates >/dev/null 2>&1; then
  echo "🔸 Atualizando store de certificados..."
  update-ca-certificates
else
  echo "⚠️  'update-ca-certificates' não encontrado — verifique manualmente."
fi

# Reinicia containerd
echo "🔸 Reiniciando containerd..."
systemctl restart containerd

# Garante a entrada do Harbor no /etc/hosts
if ! grep -q "${HARBOR_IP}  ${HARBOR_HOST}" /etc/hosts; then
  echo "${HARBOR_IP}  ${HARBOR_HOST}" >> /etc/hosts
  echo "🔸 Entrada adicionada ao /etc/hosts"
else
  echo "ℹ️  Entrada já existe no /etc/hosts"
fi

echo "✅ Node ${node_ip} atualizado com sucesso!"
EOF
}

# ==============================
# 🚀 EXECUÇÃO
# ==============================

for NODE in $NODE_IPS; do
  update_node "$NODE"
done

echo
echo "🎉 Atualização concluída com sucesso em todos os nodes do cluster!"
 
