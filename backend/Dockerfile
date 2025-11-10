# Stage 1: Build
# This is AMD but Final image on ARM, You can use --platform=linux/arm64 (Before 'node')  here to make it ARM
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

#added
RUN npm ci --only=production && npm cache clean --force 

# Stage 2: Runtime
FROM ghcr.io/rajarshigit2441139/base_images/node-18.16.0-arm64:16

# (Inherits WORKDIR and USER from runtime)
COPY --from=builder /app /usr/src/node_app

ENV NODE_ENV=production
EXPOSE 5001

CMD ["npm", "start"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5001/health || exit 1
