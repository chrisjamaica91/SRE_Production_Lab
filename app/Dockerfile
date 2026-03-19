# ===================================
# Stage 1: Build Stage
# ===================================
FROM node:20-alpine3.22 AS builder

WORKDIR /usr/src/app

# Copy package files first (for Docker layer caching)
COPY package*.json ./

# Install all dependencies
RUN npm ci

# Copy source code
COPY . .

# ===================================
# Stage 2: Production Stage
# ===================================
FROM node:20-alpine3.22

# Add labels for documentation
LABEL maintainer="chris@srelab.com"
LABEL version="1.0.0"
LABEL description="SRE Lab API - Enterprise Grade Application"

# Security: Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /usr/src/app

# Copy package files and install only production dependencies
COPY --from=builder /usr/src/app/package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Copy source code from builder  
COPY --from=builder /usr/src/app/src ./src
COPY --from=builder /usr/src/app/migrations ./migrations

# Change ownership to non-root user
RUN chown -R nodejs:nodejs /usr/src/app

# Switch to non-root user
USER nodejs

# Expose application port
EXPOSE 3000

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "src/server.js"]
