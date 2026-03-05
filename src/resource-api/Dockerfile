FROM node:20-alpine

WORKDIR /app

# Install deps first for layer caching
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

COPY . .

# Non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 3000

CMD ["node", "index.js"]
