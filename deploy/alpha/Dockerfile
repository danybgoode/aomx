FROM node:24-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY src/funnel ./src/funnel
COPY src/alpha ./src/alpha
COPY scripts/alpha-server.mjs ./scripts/alpha-server.mjs
USER node
EXPOSE 8787
CMD ["node", "scripts/alpha-server.mjs"]
