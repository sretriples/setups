# Instalação do Harbor em Máquina Virtual

## Requisitos

Antes de começar, verifique se você tem os seguintes pré-requisitos:

- Máquina virtual com Ubuntu 24.04 ou 26.04.
- Segundo disco dedicado para dados, montado em `/data`.
- Acesso liberado à internet.

## Etapa 1: Instalando o Docker

Instale os pré-requisitos:
```bash
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y vim ca-certificates curl gnupg lsb-release
```

Adicione a chave GPG do Docker:
```bash
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
```

Adicione o repositório do Docker:
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Instale o Docker e os plugins necessários:
```bash
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Adicione seu usuário ao grupo do Docker e reinicie a sessão do usuário:
```bash
sudo usermod -aG docker $USER
```

Depois desse comando, faça logout e login novamente para que a nova associação ao grupo passe a valer.

Habilite e inicie o serviço do Docker:
```bash
sudo systemctl enable --now docker
sudo systemctl status docker
```

## Etapa 2: Download do Harbor

Acesse o diretório de dados e baixe a versão desejada do Harbor, conforme o repositório oficial do [GitHub](https://github.com/goharbor/harbor/releases):
```bash
cd /data
sudo wget https://github.com/goharbor/harbor/releases/download/v2.14.4/harbor-online-installer-v2.14.4.tgz
```

Descompacte o pacote:
```bash
sudo tar -xvf harbor-online-installer-v2.14.4.tgz
```

Crie o diretório de certificados:
```bash
sudo mkdir -p /data/certs
cd /data/certs
```

Crie a cadeia de certificados da CA e copie-a para o diretório do Docker. Substitua `<harbor.dominio.com.br>` pelo hostname real do Harbor:
```bash
sudo mkdir -p /etc/docker/certs.d/<harbor.dominio.com.br>/
sudo cp /data/certs/ca.crt /etc/docker/certs.d/<harbor.dominio.com.br>/ca.crt
```

Reinicie o Docker para carregar o certificado:
```bash
sudo systemctl restart docker
sudo systemctl status docker
```

## Etapa 3: Configurando e instalando o Harbor

Acesse o diretório do instalador e crie uma cópia do arquivo de configuração:
```bash
cd /data/harbor
sudo cp harbor.yml.tmpl harbor.yml
```

Edite os parâmetros do Harbor:
```bash
sudo vim harbor.yml
```

Use o exemplo abaixo como referência:
```yaml
hostname: harbor.dominio.com.br

http:
  port: 80

https:
  port: 443
  certificate: /data/certs/fullchain.pem
  private_key: /data/certs/privkey.pem

external_url: https://harbor.dominio.com.br

data_volume: /data

harbor_admin_password: StrongAdminPassword123!

database:
  password: StrongDBPassword123!
```

Execute a preparação e a instalação do Harbor:
```bash
sudo ./prepare
sudo ./install.sh --with-trivy
```

Valide a instalação:
```bash
docker ps -a
```

## Etapa 4: Criando o serviço systemd para o Harbor

Crie o arquivo de serviço:
```bash
sudo tee /etc/systemd/system/harbor.service > /dev/null << 'EOF'
[Unit]
Description=Harbor Registry Service
After=docker.service network-online.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/data/harbor
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
EOF
```

Recarregue os daemons, habilite e inicie o serviço:
```bash
sudo systemctl daemon-reload
sudo systemctl enable harbor.service --now
sudo systemctl status harbor.service
```

## Etapa 5: Upgrade do Harbor

### Etapa 5.1: Backup do Harbor atual

Pare o serviço:
```bash
sudo systemctl stop harbor.service
sudo systemctl status harbor.service
```

Crie um diretório de backup:
```bash
sudo mkdir -p /data/harbor_v2.14.4_bkp
```

Faça backup das configurações e dados:
```bash
cd /data/harbor
sudo cp harbor.yml /data/harbor_v2.14.4_bkp/
sudo cp -r common/ /data/harbor_v2.14.4_bkp/common_backup/
sudo tar -czvf /data/harbor_v2.14.4_bkp/database_backup.tar.gz /data/database /data/secret
```

### Etapa 5.2: Baixando a versão mais recente

Baixe a nova versão do Harbor, conforme o repositório oficial do [GitHub](https://github.com/goharbor/harbor/releases):
```bash
cd /data
sudo wget https://github.com/goharbor/harbor/releases/download/v2.15.1/harbor-online-installer-v2.15.1.tgz
```

Extraia o instalador em um diretório próprio:
```bash
sudo mkdir -p /data/harbor_v2.15.1
sudo tar -xzvf harbor-online-installer-v2.15.1.tgz -C /data/harbor_v2.15.1/
```

### Etapa 5.3: Ajustando as configurações

Copie os arquivos de instalação e configuração para o diretório antigo do Harbor:
```bash
cd /data/harbor
sudo cp /data/harbor_v2.15.1/harbor/install.sh .
sudo cp /data/harbor_v2.15.1/harbor/prepare .
sudo cp /data/harbor_v2.15.1/harbor/common.sh .
```

### Etapa 5.4: Executando o upgrade

Execute o preparo do Harbor atualizado e reinicie o serviço:
```bash
sudo ./prepare --with-trivy
sudo systemctl start harbor.service
sudo systemctl status harbor.service
```

Verifique o estado dos containers e logs:
```bash
docker ps -a
docker compose logs -f
```

Remova as imagens antigas, se necessário:
```bash
docker images
docker rmi $(docker images --format "{{.Repository}}:{{.Tag}}" | grep "v2.14.4")
```

### Equipe responsável pela Documentação

| Autor(es)/Revisor(es) | Atividade(s) |
| --- | --- |
| Carlos Papalardo | Criação da documentação |
| Anderson Silva | Revisão da documentação |