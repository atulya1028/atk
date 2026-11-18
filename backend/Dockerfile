FROM node:24-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY src ./src
COPY prisma ./prisma
COPY prisma.config.ts ./prisma.config.ts
RUN npx prisma generate
RUN chown -R node:node /app
USER node
EXPOSE 8080
CMD ["sh", "-c", "npm run migrate && npm start"]
