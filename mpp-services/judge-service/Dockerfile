FROM node:20-alpine
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

COPY server.js ./

ENV NODE_ENV=production
ENV HOST=0.0.0.0
EXPOSE 4102

CMD ["node", "server.js"]
