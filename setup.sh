#!/usr/bin/env sh

#TODO:
# - Criar funcao para verficar se o arquivo de credenciais existe 
# - Criar funcao para verificar se o arquivo de token existe
# - Criar funcao para verificar se o arquivo de log existe

set -e

os=$(uname | tr '[:upper:]' '[:lower:]')
arch=$(uname -m | tr '[:upper:]' '[:lower:]' | sed -e s/x86_64/amd64/)

if [ "$arch" = "aarch64" ]; then
  arch="arm64"
fi

install_package() {
  PACKAGE=$1
  if [ -x "$(command -v apt)" ]; then
    sudo apt update && sudo apt install -y "$PACKAGE"
  elif [ -x "$(command -v dnf)" ]; then
    sudo dnf install -y "$PACKAGE"
  elif [ -x "$(command -v yum)" ]; then
    sudo yum install -y "$PACKAGE"
  elif [ -x "$(command -v zypper)" ]; then
    sudo zypper install -y "$PACKAGE"
  else
    exit 1
  fi
}

if ! command -v apt > /dev/null 2>&1; then
  if command -v dnf > /dev/null 2>&1; then
    install_package "python3"
  elif command -v yum > /dev/null 2>&1; then
    install_package "python3"
  elif command -v zypper > /dev/null 2>&1; then
    install_package "python3"
  else
    exit 1
  fi
else
  install_package "python3" && install_package "python3.12-venv"
fi

if [ ! -d "$HOME/backup-drive" ]; then
  python3 -m venv "$HOME/backup-drive"
fi

. "$HOME/backup-drive/bin/activate"

pip install --upgrade pip

if ! command -v pip > /dev/null 2>&1; then
  python -m ensurepip --upgrade
fi

if ! command -v aws > /dev/null 2>&1; then
  install_package "unzip"
  if [ "$os" = "linux" ]; then
    if [ "$arch" = "amd64" ]; then
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    elif [ "$arch" = "arm64" ]; then
      curl "https://awscli.amazonaws.com/awscli-exe-linux-arm64.zip" -o "awscliv2.zip"
    else
      echo "Arquitetura não suportada para o AWS CLI."
      exit 1
    fi

    if [ ! -f awscliv2.zip ]; then
      echo "Erro: O arquivo awscliv2.zip não foi baixado corretamente."
      exit 1
    fi

    unzip -t awscliv2.zip || { echo "Erro: Arquivo AWS CLI corrompido."; exit 1; }

    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
  else
    echo "Sistema não suportado para a instalação do AWS CLI. Instale manualmente."
    exit 1
  fi
fi


if [ -f "$HOME/backup-drive/requirements.txt" ]; then

  pip install -r "$HOME/backup-drive/requirements.txt"

else

  pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client boto3

fi


if ! command -v git > /dev/null 2>&1; then
 
  install_package "git-core"
fi


if ! command -v crontab > /dev/null 2>&1; then

  if [ -f /etc/os-release ] && grep -qi "amazon linux" /etc/os-release; then

    sudo yum install -y cronie

  elif [ -f /etc/os-release ] && grep -qi "suse" /etc/os-release; then

    sudo zypper install -y cron  # No SUSE, o pacote correto é 'cron', não 'cronie'

  elif [ -x "$(command -v dnf)" ]; then

    sudo dnf install -y cronie

  else

    install_package "cron"
  fi
fi

if [ -x "$(command -v systemctl)" ]; then

  if systemctl list-units --type=service | grep -qi "crond.service"; then

    sudo systemctl enable crond
    sudo systemctl start crond

  elif systemctl list-units --type=service | grep -qi "cron.service"; then

    sudo systemctl enable cron
    sudo systemctl start cron

  elif systemctl list-units --type=service | grep -qi "cronie.service"; then

    sudo systemctl enable cronie
    sudo systemctl start cronie

  else
    echo "Nenhum serviço de cron encontrado. Verifique a instalação."
  fi
fi



# Defina o caminho onde o script Python será salvo
PYTHON_SCRIPT_PATH="$HOME/backup-drive/gdxpt.py"

cat << 'EOF' > "$PYTHON_SCRIPT_PATH"
import os
import csv
import google.auth
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from google.oauth2 import service_account
import datetime
import pickle
import logging
import unicodedata
import shutil
import tarfile
import boto3

# Função para remover acentos de strings
def remove_acentos(texto):
    return ''.join((c for c in unicodedata.normalize('NFD', texto) if unicodedata.category(c) != 'Mn'))

# Defina o escopo de acesso
SCOPES = ['https://www.googleapis.com/auth/spreadsheets.readonly', 'https://www.googleapis.com/auth/drive.readonly']

# Caminho para o arquivo de credenciais da conta de serviço (arquivo JSON)

SERVICE_ACCOUNT_FILE = os.path.expanduser('~') + '/backup-drive/sa.json'

# Caminho para o arquivo de token (onde o token será armazenado)

TOKEN_PATH = os.path.expanduser('~') + '/backup-drive/token.pickle'


# Função para autenticação e criação do cliente de API usando a Conta de Serviço
def get_google_service(service_name, version):
    creds = None
    # O token de autenticação pode já existir, então tente carregá-lo
    if os.path.exists(TOKEN_PATH):
        with open(TOKEN_PATH, 'rb') as token:
            creds = pickle.load(token)

    # Se as credenciais não forem válidas ou expiradas, faça a autenticação novamente
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())  # Renova o token de acesso
        else:
            creds = service_account.Credentials.from_service_account_file(
                SERVICE_ACCOUNT_FILE, scopes=SCOPES)
        
        # Salve as credenciais renovadas no arquivo token.pickle
        with open(TOKEN_PATH, 'wb') as token:
            pickle.dump(creds, token)

    # Crie o serviço da API (Drive ou Sheets)
    service = build(service_name, version, credentials=creds)
    return service

# Função para listar os diretórios no Google Drive (somente pastas)
def list_directories():
    try:
        logging.info("Iniciando listagem de diretórios no Google Drive.")
        drive_service = get_google_service('drive', 'v3')
        query = "mimeType='application/vnd.google-apps.folder'"
        results = drive_service.files().list(q=query, fields="files(id, name, parents)").execute()
        files = results.get('files', [])
        
        if not files:
            logging.warning('Nenhum diretório encontrado no Google Drive.')
        else:
            logging.info(f'{len(files)} diretórios encontrados no Google Drive.')
            for file in files:
                logging.info(f"{file['name']} (ID: {file['id']})")
        return files
    except Exception as e:
        logging.error(f"Erro ao acessar o Google Drive: {e}")
        return []

# Função para listar as planilhas no Google Drive
def list_spreadsheets():
    try:
        logging.info("Iniciando listagem de planilhas no Google Drive.")
        drive_service = get_google_service('drive', 'v3')
        query = "mimeType='application/vnd.google-apps.spreadsheet'"
        results = drive_service.files().list(q=query, fields="files(id, name, parents)").execute()
        files = results.get('files', [])
        
        if not files:
            logging.warning('Nenhuma planilha encontrada no Google Drive.')
        else:
            logging.info(f'{len(files)} planilhas encontradas no Google Drive.')
            for file in files:
                logging.info(f"{file['name']} (ID: {file['id']})")
        return files
    except Exception as e:
        logging.error(f"Erro ao acessar o Google Drive: {e}")
        return []

# Função para listar as abas (intervalos) de uma planilha
def list_sheets(spreadsheet_id):
    try:
        logging.info(f"Iniciando listagem de abas para a planilha {spreadsheet_id}.")
        sheets_service = get_google_service('sheets', 'v4')
        result = sheets_service.spreadsheets().get(spreadsheetId=spreadsheet_id).execute()
        sheets = result.get('sheets', [])
        return [sheet['properties']['title'] for sheet in sheets]
    except HttpError as err:
        logging.error(f"Erro ao acessar a planilha {spreadsheet_id}: {err}")
        return []
    except Exception as e:
        logging.error(f"Erro inesperado: {e}")
        return []

# Função para exportar os dados de uma planilha para CSV
def export_google_sheet_to_csv(spreadsheet_id, range_name, output_file):
    try:
        logging.info(f"Iniciando exportação da planilha {spreadsheet_id} intervalo {range_name} para CSV.")
        sheets_service = get_google_service('sheets', 'v4')
        result = sheets_service.spreadsheets().values().get(spreadsheetId=spreadsheet_id, range=range_name).execute()
        values = result.get('values', [])

        if not values:
            logging.warning(f'Nenhum dado encontrado no intervalo {range_name} da planilha {spreadsheet_id}. Não será exportada para o diretório local')
        else:
            with open(output_file, mode='w', newline='', encoding='utf-8') as file:
                writer = csv.writer(file)
                writer.writerows(values)
                logging.info(f"Dados do intervalo {range_name} exportados com sucesso para: {output_file}")
    except HttpError as err:
        logging.error(f"Erro ao exportar os dados da planilha {spreadsheet_id}, intervalo {range_name}: {err}")
    except Exception as e:
        logging.error(f"Erro inesperado: {e}")

# Função para renomear arquivos ou diretórios, removendo acentos
def rename_files_and_directories(base_path):
    for root, dirs, files in os.walk(base_path, topdown=False):
        for name in files:
            original_file = os.path.join(root, name)
            new_name = remove_acentos(name)
            new_file = os.path.join(root, new_name)
            if original_file != new_file:
                shutil.move(original_file, new_file)
                logging.info(f"Renomeado arquivo {original_file} para {new_file}")

        for name in dirs:
            original_dir = os.path.join(root, name)
            new_name = remove_acentos(name)
            new_dir = os.path.join(root, new_name)
            if original_dir != new_dir:
                shutil.move(original_dir, new_dir)
                logging.info(f"Renomeado diretório {original_dir} para {new_dir}")

# Função para compactar arquivos em tar
def compress_directory_to_tar(base_path):
    current_datetime = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M")
    tar_filename = f"{current_datetime}--gsheet-bkp.tar"
    tar_path = os.path.join(base_path, tar_filename)
    with tarfile.open(tar_path, "w") as tar:
        for root, dirs, files in os.walk(base_path):
            for file in files:
                file_path = os.path.join(root, file)
                tar.add(file_path, arcname=os.path.relpath(file_path, base_path))
    logging.info(f"Arquivo compactado criado: {tar_path}")
    return tar_path

# Função para enviar arquivo para o bucket S3
def upload_to_s3(file_path, bucket_name):
    s3 = boto3.client('s3')
    file_name = os.path.basename(file_path)
    try:
        s3.upload_file(file_path, bucket_name, file_name)
        logging.info(f"Arquivo {file_name} enviado para o bucket {bucket_name}.")
    except Exception as e:
        logging.error(f"Erro ao enviar o arquivo {file_name} para o S3: {e}")

# Função principal
def main():
    # Obter a data e hora atual
    current_datetime = datetime.datetime.now()
    year = current_datetime.year
    month = current_datetime.month
    day = current_datetime.day
    hour = current_datetime.hour
    minute = current_datetime.minute

    # Criar diretórios para ano, mês, dia e hora
    root_dir = os.path.join(str(year), str(month).zfill(2), str(day).zfill(2), str(hour).zfill(2))
    os.makedirs(root_dir, exist_ok=True)

    # Criar diretório para logs com o novo caminho fixado
    log_dir = os.path.join(str(year), 'logs')
    os.makedirs(log_dir, exist_ok=True)

    # Criar o arquivo de log com o formato de nome desejado
    log_file = os.path.join(log_dir, f"{str(year)}-{str(month).zfill(2)}-{str(day).zfill(2)}_{str(hour).zfill(2)}-{str(minute).zfill(2)}-execution-logs.log")
    logging.basicConfig(filename=log_file, level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    logging.info("Início da execução do script.")

    # Obter todos os diretórios do Google Drive
    directories = list_directories()
    if not directories:
        logging.warning("Nenhum diretório encontrado no Google Drive.")
        return

    # Obter todas as planilhas do Google Drive
    spreadsheets = list_spreadsheets()
    if not spreadsheets:
        logging.warning("Nenhuma planilha encontrada no Google Drive.")
        return

    # Processar cada diretório e planilha
    for directory in directories:
        directory_name = directory['name']  # Nome do diretório
        directory_id = directory['id']  # ID do diretório
        logging.info(f"Processando diretório: {directory_name} (ID: {directory_id})")

        # Criar o diretório correspondente à estrutura do Google Drive
        drive_directory_path = os.path.join(root_dir, directory_name)
        os.makedirs(drive_directory_path, exist_ok=True)

        # Processar cada planilha
        for sheet in spreadsheets:
            spreadsheet_id = sheet['id']
            sheet_name = sheet['name']
            parents = sheet.get('parents', [])

            # Verifica se a planilha está dentro do diretório
            if directory_id in parents:
                logging.info(f"A planilha {sheet_name} está dentro do diretório {directory_name}.")
                
                # Obter as abas (intervalos) da planilha
                sheet_tabs = list_sheets(spreadsheet_id)
                if not sheet_tabs:
                    logging.warning(f"Nenhuma aba encontrada na planilha {sheet_name}.")
                    continue

                # Para cada aba, exportar os dados para CSV
                for tab_name in sheet_tabs:
                    file_name = f"{sheet_name}_{tab_name}.csv".replace(" ", "_")
                    output_file = os.path.join(drive_directory_path, file_name)
                    export_google_sheet_to_csv(spreadsheet_id, tab_name, output_file)

        # Após salvar, renomear arquivos e diretórios removendo acentos
        rename_files_and_directories(root_dir)

    # Compactar os arquivos e fazer o upload para o S3
    tar_file = compress_directory_to_tar(root_dir)
    upload_to_s3(tar_file, 'gsheet-export')

    logging.info("Execução do script concluída.")


if __name__ == '__main__':
    main()

EOF

# Adiciona o diretório bin ao PATH no cron
echo "Configurando o cron job com o PATH ajustado"
(crontab -l 2>/dev/null; echo "PATH=$HOME/backup-drive/bin:$PATH") | crontab -

# Adiciona o cron job para rodar o script Python todos os dias às 19:00
(crontab -l 2>/dev/null; echo "0 19 * * * $HOME/backup-drive/bin/python3 $HOME/backup-drive/gdxpt.py >> $HOME/backup-drive/gdxpt.log 2>&1") | crontab -

echo "Cron job configurado com sucesso."


echo "Ambiente de execução configurado com sucesso!"