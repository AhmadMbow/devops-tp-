# Image legere officielle Node.js
FROM node:18-alpine

# Repertoire de travail dans le conteneur
WORKDIR /usr/src/app

# On copie d'abord les manifestes pour profiter du cache Docker
COPY package*.json ./

# Installation des dependances de production uniquement
RUN npm install --omit=dev

# Copie du reste du code source
COPY . .

# Port expose par l'application
EXPOSE 3000

# Healthcheck : verifie que /health repond
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Commande de demarrage
CMD ["npm", "start"]
