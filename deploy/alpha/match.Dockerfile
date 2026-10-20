FROM node:24-bookworm-slim
ARG TARGETARCH
RUN case "$TARGETARCH" in amd64|arm64) ;; *) exit 1 ;; esac
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip libfontconfig1 \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
RUN case "$TARGETARCH" in \
    amd64) godot_sha=cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4; godot_arch=x86_64 ;; \
    arm64) godot_sha=5dd0d86405cf7e8adf79fb6377b38ba682a2846cb378ffe5364f38c01ad29b9d; godot_arch=arm64 ;; \
  esac \
  && curl -fsSL -o /tmp/godot.zip "https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.$godot_arch.zip" \
  && echo "$godot_sha  /tmp/godot.zip" | sha256sum -c - \
  && unzip -q /tmp/godot.zip -d /usr/local/bin \
  && mv "/usr/local/bin/Godot_v4.7.2-stable_linux.$godot_arch" /usr/local/bin/godot \
  && chmod 755 /usr/local/bin/godot \
  && rm /tmp/godot.zip
COPY src/multiplayer ./src/multiplayer
COPY scripts/multiplayer-server.mjs ./scripts/multiplayer-server.mjs
COPY game ./game
ENV AOMX_GODOT_BIN=/usr/local/bin/godot AOMX_GAME_PATH=/app/game HOME=/tmp
USER node
EXPOSE 8790
CMD ["node", "scripts/multiplayer-server.mjs"]
