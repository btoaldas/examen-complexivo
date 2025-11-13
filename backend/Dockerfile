FROM node:18-alpine

WORKDIR /app

# Instalar dependencias
COPY package*.json ./
RUN npm install --production

# Copiar código fuente
COPY . .

# Exponer puerto
EXPOSE 5000

# Comando de inicio
CMD ["npm", "start"]
