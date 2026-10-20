FROM node:24-bookworm-slim
ARG TARGETARCH
RUN test "$TARGETARCH" = amd64
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip libfontconfig1 \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
RUN curl -fsSL -o /tmp/godot.zip https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip \
  && echo 'cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4  /tmp/godot.zip' | sha256sum -c - \
  && unzip -q /tmp/godot.zip -d /usr/local/bin \
  && mv /usr/local/bin/Godot_v4.7.2-stable_linux.x86_64 /usr/local/bin/godot \
  && chmod 755 /usr/local/bin/godot \
  && rm /tmp/godot.zip
COPY src/multiplayer ./src/multiplayer
COPY scripts/multiplayer-server.mjs ./scripts/multiplayer-server.mjs
COPY game ./game
ENV AOMX_GODOT_BIN=/usr/local/bin/godot AOMX_GAME_PATH=/app/game HOME=/tmp
USER node
EXPOSE 8790
CMD ["node", "scripts/multiplayer-server.mjs"]
