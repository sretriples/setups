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

# Detectando a distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    log "❌ Não foi possível detectar a distribuição Linux."
    exit 1
fi

ARCH=$(uname -m)
log "🔍 Distribuição detectada: $DISTRO / Arquitetura: $ARCH"

log "🌐 Verificando conectividade com a internet..."
curl -s --head https://www.google.com | head -n 1 | grep "200" > /dev/null
if [ $? -ne 0 ]; then
    log "❌ Sem conexão com a internet. Interrompendo instalação."
    exit 1
fi

# Funções específicas por distro
install_dependencies_ubuntu() {
    run_cmd "sudo apt update"
    run_cmd "sudo apt install -y ca-certificates curl apt-transport-https software-properties-common python3-pip virtualenv python3-setuptools gnupg-agent lsb-release"
}

install_dependencies_rhel() {
    RHEL_VERSION=$(rpm -E %{rhel})
    ARCH=$(uname -m)
    CODEREADY_REPO="codeready-builder-for-rhel-${RHEL_VERSION}-${ARCH}-rpms"

    log "📦 Habilitando repositório oficial suportado pela Red Hat: $CODEREADY_REPO"
    run_cmd "sudo subscription-manager repos --enable=${CODEREADY_REPO}"

    run_cmd "sudo dnf -y install ca-certificates curl gnupg2"
}

install_docker_ubuntu() {
    run_cmd "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
    run_cmd "echo 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"
    run_cmd "sudo apt update"
    run_cmd "sudo apt install -y docker-ce docker-ce-cli containerd.io"
}

install_docker_rhel() {
    run_cmd "sudo dnf -y install dnf-plugins-core"
    run_cmd "sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo"
    run_cmd "sudo dnf install -y docker-ce docker-ce-cli containerd.io"
}

install_tanzu_ubuntu() {
    run_cmd "sudo mkdir -p /etc/apt/keyrings"
    run_cmd "curl -fsSL https://storage.googleapis.com/tanzu-cli-installer-packages/keys/TANZU-PACKAGING-GPG-RSA-KEY.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/tanzu-archive-keyring.gpg"
    run_cmd "echo 'deb [signed-by=/etc/apt/keyrings/tanzu-archive-keyring.gpg] https://storage.googleapis.com/tanzu-cli-installer-packages/apt tanzu-cli-jessie main' | sudo tee /etc/apt/sources.list.d/tanzu.list"
    run_cmd "sudo apt update"
    run_cmd "sudo apt install -y tanzu-cli=1.5.3"
}
 
install_tanzu_rhel() {
    if [[ "$ARCH" == "aarch64" ]]; then
        TANZU_RPM_URL="https://storage.googleapis.com/tanzu-cli-installer-packages/rpm/tanzu-cli/tanzu-cli-1.5.3-1.aarch64.rpm"
    else
        TANZU_RPM_URL="https://storage.googleapis.com/tanzu-cli-installer-packages/rpm/tanzu-cli/tanzu-cli-1.5.3-1.x86_64.rpm"
    fi

    RPM_TMP_FILE="/tmp/tanzu-cli-1.5.3.rpm"
    log "⬇️ Baixando Tanzu CLI RPM..."
    run_cmd "curl -L -o $RPM_TMP_FILE $TANZU_RPM_URL"

    log "📦 Instalando Tanzu CLI via rpm..."
    run_cmd "sudo rpm -ivh $RPM_TMP_FILE"
}

# Instalação base por distribuição
case "$DISTRO" in
    ubuntu)
        install_dependencies_ubuntu
        install_docker_ubuntu
        install_tanzu_ubuntu
        ;;
    rhel|centos|fedora)
        install_dependencies_rhel
        install_docker_rhel
        install_tanzu_rhel
        ;;
    *)
        log "❌ Distribuição não suportada automaticamente: $DISTRO"
        exit 1
        ;;
esac

run_cmd "sudo usermod -aG docker \$USER"


log "⚙️ Configurando Docker..."
run_cmd "echo '{\"exec-opts\": [\"native.cgroupdriver=systemd\"]}' | sudo tee /etc/docker/daemon.json > /dev/null"
run_cmd "sudo systemctl daemon-reload"
run_cmd "sudo systemctl restart docker"
run_cmd "sudo systemctl enable docker"

log "🔌 Instalando plugins do Tanzu CLI..."
#run_cmd "tanzu config eula accept"
#run_cmd "TANZU_CLI_NO_INIT=true TANZU_CLI_EULA_PROMPT_ANSWER=yes TANZU_CLI_CEIP_OPT_IN_PROMPT_ANSWER=no tanzu plugin install --group vmware-tkg/default:v2.5.4"
#run_cmd "tanzu plugin install --group vmware-tkg/default:v2.5.4"
run_cmd "tanzu plugin install cluster --target k8s"
run_cmd "tanzu plugin install secret --target k8s"

log "⚓ Instalando Helm..."
run_cmd "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"

log "📦 Instalando ferramentas Carvel..."
dst_dir="/usr/local/bin"
dl_bin="curl -s -L"
binary_type="linux-amd64"

# Detectar comando de verificação de hash disponível
if command -v shasum &>/dev/null; then
    hash_cmd="shasum -a 256"
elif command -v sha256sum &>/dev/null; then
    hash_cmd="sha256sum"
elif command -v openssl &>/dev/null; then
    hash_cmd="openssl dgst -sha256"
else
    echo "❌ Nenhuma ferramenta de verificação SHA256 encontrada (shasum, sha256sum ou openssl)."
    exit 1
fi

declare -A tools=(
  [ytt]="https://github.com/sretriples/setups/raw/main/pkgs/ytt 8e4696f024e6d75a6f12c71914d0d350323e2602489da32ab019e1f2bf872a4b"
  [imgpkg]="https://github.com/sretriples/setups/raw/main/pkgs/imgpkg 66ef9022b01331b6b0e6d38c85e9a9537d77bf005f2ca7d5c25805c14884b258"
  [kbld]="https://github.com/sretriples/setups/raw/main/pkgs/kbld 8565e5c9864696e705acb6ff9b5029c1464defda23fc922c1a29727aedb1b8ff"
  [kapp]="https://github.com/sretriples/setups/raw/main/pkgs/kapp 040af12be6c0c13c0b0f1a9e4d75fcf9265c27df1b35192edd4a6545cd372f2c"
  [vendir]="https://github.com/sretriples/setups/raw/main/pkgs/vendir d6cae2f1a9236dae1a7fa89e165cb78d08c4c1ae57b0611072a7dd4187775300"
)


for tool in "${!tools[@]}"; do
    url_checksum=(${tools[$tool]})
    url=${url_checksum[0]}
    checksum=${url_checksum[1]}

    log "⬇️ Instalando ${tool}..."
    $dl_bin "$url" > "/tmp/${tool}"

    if [[ $hash_cmd == openssl* ]]; then
        file_hash=$($hash_cmd /tmp/${tool} | awk '{print $2}')
        if [[ "$file_hash" != "$checksum" ]]; then
            log "❌ Falha na verificação de integridade do ${tool}"
            continue
        fi
    else
        echo "${checksum}  /tmp/${tool}" | $hash_cmd -c - >>"$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            log "❌ Falha na verificação de integridade do ${tool}"
            continue
        fi
    fi

    run_cmd "sudo mv /tmp/${tool} ${dst_dir}/${tool}"
    run_cmd "sudo chmod +x ${dst_dir}/${tool}"
    log "✅ ${tool} instalado com sucesso."
done

log "📥 Instalando kubectl..."

KUBECTL_VERSION="v1.30.9+vmware.3"
KUBECTL_URL="https://github.com/sretriples/setups/raw/main/pkgs/kubectl.gz"
KUBECTL_TMP="/tmp/kubectl.gz"
KUBECTL_BIN="/tmp/kubectl"
KUBECTL_DST="/usr/local/bin/kubectl"

log "⬇️ Baixando kubectl de: $KUBECTL_URL"
run_cmd "curl -L -o ${KUBECTL_TMP} ${KUBECTL_URL}"

log "📦 Descompactando kubectl..."
run_cmd "gunzip -f ${KUBECTL_TMP}"

if [ ! -f "${KUBECTL_BIN}" ]; then
    log "❌ Arquivo kubectl não encontrado após descompactação."
    exit 1
fi

log "🚚 Movendo kubectl para ${KUBECTL_DST}"
run_cmd "sudo mv ${KUBECTL_BIN} ${KUBECTL_DST}"

log "🔐 Ajustando permissões do kubectl"
run_cmd "sudo chmod +x ${KUBECTL_DST}"

log "✅ kubectl instalado com sucesso"


log "✅ Instalação concluída. Verifique o log completo em: $LOG_FILE"
log " "
log " "
log " "
log "⚠️ Reinicie a sessão para aplicar o grupo docker ao usuário!! ⚠️"