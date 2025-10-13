# Usa imagem oficial do Node.js como base
FROM node:18-alpine

# Diretório de trabalho dentro do container
WORKDIR /app

# Copia os arquivos package.json e package-lock.json (se existir)
COPY package*.json ./

# Instala as dependências do Node
RUN npm install

# Copia todo o restante do código da aplicação para dentro do container
COPY . .

# Expõe a porta que o app vai usar (exemplo: 3000)
EXPOSE 3000

# Comando para iniciar a aplicação
CMD ["node", "index.js"]
