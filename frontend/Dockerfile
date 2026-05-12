# Build stage
FROM node:18-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM ghcr.io/rajarshigit2441139/base_images/nginx-1.29-arm64:4

# envsubst
RUN apk add --no-cache gettext

COPY --from=build /app/dist /usr/share/nginx/html

COPY nginx.conf.template /etc/nginx/templates/default.conf.template

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

USER root

RUN mkdir -p /run /var/cache/nginx /var/log/nginx \
    && chown -R nginx:nginx /run /var/cache/nginx /var/log/nginx \
    && chown -R nginx:nginx /usr/share/nginx/html

USER nginx

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]