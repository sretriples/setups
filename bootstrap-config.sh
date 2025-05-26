#!/bin/bash

# Nome do log
LOG_FILE="$(date +'%d-%m-%y-%H_%M')-loginstall.log"

# Função de log
log() {
    echo -e "$(date +'%d-%m-%y %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Função para executar comandos com verificação de erro
run_cmd() {
    log "▶️ Executando: $1"
    eval "$1" >>"$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log "❌ Erro ao executar: $1"
    else
        log "✅ Sucesso: $1"
    fi
}

# Validação do shell
if test -z "$BASH_VERSION"; then
  log "❌ Este script deve ser executado com bash, não sh."
  exit 1
fi

log "🚀 Início da instalação..."

log "🌐 Verificando conectividade com a internet..."
curl -s --head https://www.google.com | head -n 1 | grep "200" > /dev/null
if [ $? -ne 0 ]; then
    log "❌ Sem conexão com a internet. Interrompendo instalação."
    exit 1
fi

log "🔄 Atualizando pacotes do sistema..."
run_cmd "sudo apt update"

log "📦 Instalando dependências essenciais..."
run_cmd "sudo apt install -y ca-certificates curl apt-transport-https software-properties-common python3-pip virtualenv python3-setuptools gnupg-agent lsb-release"

log "🌐 Instalando Tanzu CLI..."
run_cmd "sudo mkdir -p /etc/apt/keyrings"
run_cmd "curl -fsSL https://storage.googleapis.com/tanzu-cli-installer-packages/keys/TANZU-PACKAGING-GPG-RSA-KEY.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/tanzu-archive-keyring.gpg"
run_cmd "echo 'deb [signed-by=/etc/apt/keyrings/tanzu-archive-keyring.gpg] https://storage.googleapis.com/tanzu-cli-installer-packages/apt tanzu-cli-jessie main' | sudo tee /etc/apt/sources.list.d/tanzu.list"
run_cmd "sudo apt update"
run_cmd "sudo apt install -y tanzu-cli=1.3.0"

log "🔌 Instalando plugins do Tanzu CLI..."
export TANZU_CLI_CEIP_OPT_IN_PROMPT_ANSWER=no
run_cmd "tanzu config eula accept"
run_cmd "tanzu plugin install --group vmware-tkg/default:v2.5.3"
run_cmd "tanzu plugin install cluster --target k8s"
run_cmd "tanzu plugin install secret --target k8s"
run_cmd "tanzu plugin install pinniped-auth"

log "⚓ Instalando Helm..."
run_cmd "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"

log "🔧 Instalando kubectl..."
run_cmd "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
run_cmd "chmod +x kubectl"
run_cmd "sudo mv kubectl /usr/local/bin/"
log "🔗 Verificando instalação do kubectl..."

log "✅ Instalação concluída. Verifique o log completo em: $LOG_FILE"