# Dockerfile Patterns

## Purpose

Best practice Dockerfile templates for common application types. Optimized for layer caching, security, and image size.

## Official Documentation

- [Dockerfile Reference](https://docs.docker.com/reference/dockerfile/) - Complete syntax
- [Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/) - Official guide
- [Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/) - Build optimization

## When to Use

- ✅ Any application being containerized
- ✅ CI/CD pipelines building images
- ✅ Kubernetes deployments

## When NOT to Use

- ❌ Serverless functions (use native packaging)
- ❌ Non-containerized deployments
- ❌ Development-only tools (use local venv/nvm)

## Node.js Patterns

### Production Application

```dockerfile
# Dockerfile
FROM node:20-alpine AS builder
WORKDIR /app

# Dependencies (cached if package*.json unchanged)
COPY package*.json ./
RUN npm ci

# Build
COPY . .
RUN npm run build

# Production image
FROM node:20-alpine
WORKDIR /app

# Security: non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy only production assets
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

USER nodejs
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### Next.js Application

```dockerfile
# Dockerfile
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV PORT 3000

CMD ["node", "server.js"]
```

## Python Patterns

### FastAPI/Flask Application

```dockerfile
# Dockerfile
FROM python:3.11-slim AS builder
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create virtualenv
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Production image
FROM python:3.11-slim
WORKDIR /app

# Copy virtualenv
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Security: non-root user
RUN useradd -m -u 1001 appuser
USER appuser

# Copy application
COPY --chown=appuser:appuser . .

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### With uv (Modern)

```dockerfile
# Dockerfile
FROM python:3.11-slim

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --frozen --no-dev

# Copy application
COPY . .

# Run with uv
CMD ["uv", "run", "python", "-m", "myapp"]
```

## Go Patterns

### Static Binary

```dockerfile
# Dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app

# Dependencies
COPY go.mod go.sum ./
RUN go mod download

# Build static binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/server ./cmd/server

# Minimal runtime (scratch or distroless)
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/server /server
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### With Debugging (Alpine)

```dockerfile
# Dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o /app/server ./cmd/server

FROM alpine:3.19
RUN apk --no-cache add ca-certificates
RUN adduser -D -u 1001 appuser
USER appuser
COPY --from=builder /app/server /server
EXPOSE 8080
CMD ["/server"]
```

## Rust Patterns

### Release Build

```dockerfile
# Dockerfile
FROM rust:1.75 AS builder
WORKDIR /app

# Cache dependencies
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src

# Build application
COPY . .
RUN touch src/main.rs && cargo build --release

# Minimal runtime
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
RUN useradd -m -u 1001 appuser
USER appuser
COPY --from=builder /app/target/release/myapp /usr/local/bin/
EXPOSE 8080
CMD ["myapp"]
```

## General Best Practices

### Layer Ordering

```dockerfile
# Most stable → Least stable
FROM base                    # 1. Base image (rarely changes)
RUN apt-get install...       # 2. System packages
COPY package*.json ./        # 3. Dependency manifests
RUN npm install              # 4. Dependencies
COPY . .                     # 5. Application code (changes most)
RUN npm run build            # 6. Build
```

### Reduce Image Size

```dockerfile
# Use alpine or slim variants
FROM node:20-alpine          # ~50MB vs ~350MB for full
FROM python:3.11-slim        # ~130MB vs ~900MB for full

# Remove caches
RUN pip install --no-cache-dir -r requirements.txt
RUN npm ci && npm cache clean --force

# Multi-stage: don't copy build tools to final image
```

### Security

```dockerfile
# Run as non-root
RUN adduser -D -u 1001 appuser
USER appuser

# Don't store secrets in image
# Use environment variables at runtime
ENV DATABASE_URL=""

# Pin versions
FROM node:20.11.0-alpine     # Not just node:20-alpine

# Scan for vulnerabilities
# docker scout cves myimage:tag
```

### Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
```

### Build Arguments

```dockerfile
ARG NODE_VERSION=20
FROM node:${NODE_VERSION}-alpine

ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}
```

```bash
docker build --build-arg NODE_VERSION=18 --build-arg APP_VERSION=1.0.0 .
```

## Anti-Patterns

❌ **Avoid:**
```dockerfile
# Running as root (default)
# No USER instruction

# Installing unnecessary packages
RUN apt-get install vim curl wget git

# Not using .dockerignore
# Copying node_modules, .git, etc.

# Storing secrets in image
ENV API_KEY=secret123

# Single stage with build tools
FROM node:20
RUN npm ci
RUN npm run build
# Final image has all dev dependencies
```

## Validation

```bash
# Lint Dockerfile
docker run --rm -i hadolint/hadolint < Dockerfile

# Check image size
docker images myapp

# Inspect layers
docker history myapp:latest

# Scan for vulnerabilities
docker scout cves myapp:latest
```
