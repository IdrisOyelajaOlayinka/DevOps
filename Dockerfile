# Stage 1: Build the web (Next.js) app
FROM node:18-alpine AS web-builder
WORKDIR /app

# Copy the package files and install dependencies
COPY apps/web/package.json apps/web/yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy the rest of the web application files and build
COPY apps/web .
RUN yarn build

# Stage 2: Build the api (Express) app
FROM node:18-alpine AS api-builder
WORKDIR /app

# Copy the package files and install dependencies
COPY apps/api/package.json apps/api/yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy the rest of the api application files
COPY apps/api .

# Stage 3: Prepare the final image for production
FROM node:18-alpine AS final

# Create directories for web and api apps
WORKDIR /web
COPY --from=web-builder /app/.next ./.next
COPY --from=web-builder /app/public ./public
COPY --from=web-builder /app/node_modules ./node_modules
COPY --from=web-builder /app/package.json ./
COPY --from=web-builder /app/server.js ./server.js

WORKDIR /api
COPY --from=api-builder /app .
COPY --from=api-builder /app/server.js ./server.js

# Expose necessary ports (e.g., 3000 for web, 4000 for API)
EXPOSE 3000
EXPOSE 4000

# Set environment variables (if needed)
ENV NODE_ENV=production

# Start both apps using a process manager or a custom start script
WORKDIR /
COPY start.sh /start.sh
RUN chmod +x /start.sh
CMD ["sh", "/start.sh"]