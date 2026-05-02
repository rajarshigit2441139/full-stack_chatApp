# Build stage
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM ghcr.io/rajarshigit2441139/base_images/nginx-1.29-arm64:4

# Copy built files from the build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Copy Nginx config 
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Set proper ownership 
USER root

RUN mkdir -p /run /var/cache/nginx /var/log/nginx \
    && chown -R nginx:nginx /run /var/cache/nginx /var/log/nginx

RUN chown -R nginx:nginx /usr/share/nginx/html
# Set non-root user
USER nginx

# Expose Nginx port 
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]