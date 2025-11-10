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

# Copy your Nginx config if needed
COPY nginx.conf /etc/nginx/nginx.conf
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# Ensure proper ownership (since your runtime uses non-root user)
USER root
RUN chown -R nginx:nginx /usr/share/nginx/html
USER nginx

# Expose Nginx port 
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]