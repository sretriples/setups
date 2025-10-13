# Usa uma imagem oficial do Python
FROM python:3.11-slim

# Cria um diretório de trabalho
WORKDIR /app

# Copia o script para dentro do container
COPY hello.py .

# Comando padrão ao iniciar o container
CMD ["python", "hello.py"]
 
