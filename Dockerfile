# OpenCode (github.com/sst/opencode) has no official Docker image (checked:
# no `sst/opencode` on Docker Hub, GHCR denies both real names checked). The
# opencode-ai npm package resolves a platform binary (opencode-linux-arm64,
# opencode-linux-x64, ...) via an optionalDependency at install time, so a
# plain Node base plus a pinned `npm ci` is enough.
FROM node:22-slim

# iproute2 backs the optional REQUIRE_BIND_INTERFACE check in entrypoint.sh.
RUN apt-get update && apt-get install -y --no-install-recommends iproute2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    && mkdir -p /home/node/.local/share/opencode /home/node/.config/opencode /workspace \
    && chown -R node:node /app /home/node /workspace

ENV PATH="/app/node_modules/.bin:${PATH}" \
    HOME=/home/node

# Run as the image's built-in non-root user — this process gets shell/file
# access in whatever workspace is mounted, so it shouldn't also run as root.
USER node
WORKDIR /workspace
EXPOSE 4096
ENTRYPOINT ["/entrypoint.sh"]
