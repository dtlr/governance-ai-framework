# Docker Configuration Templates

## Overview

Configuration patterns for Docker and containerization, covering Dockerfile best practices and build optimization.

## Detection

**Marker Files:**
- `Dockerfile` or `Containerfile` → Docker project

**Load When:** Dockerfile exists

## Template Hierarchy

```
docker/
├── README.md               # This file
├── dockerfile-patterns.md  # Dockerfile best practices
└── dockerignore.template   # Build context optimization
```

Note: `.dockerignore` template is in `../ignore-files/dockerignore.template`

## Quick Reference

| Config | Purpose | Required When |
|--------|---------|---------------|
| `Dockerfile` | Container build instructions | Any containerized app |
| `.dockerignore` | Exclude from build context | Any Dockerfile |
| `docker-compose.yml` | Multi-container orchestration | Local dev, simple deployments |

## Common Commands

```bash
# Build image
docker build -t myapp:latest .

# Build with build args
docker build --build-arg VERSION=1.0 -t myapp:1.0 .

# Run container
docker run -p 8080:8080 myapp:latest

# Run with env vars
docker run -e DATABASE_URL=... myapp:latest

# List images
docker images

# Remove image
docker rmi myapp:latest

# View build context size
docker build . 2>&1 | grep "Sending build context"
```

## Dockerfile Best Practices

### Layer Caching

Order matters! Put stable layers first:

```dockerfile
# Good - dependencies cached separately
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Bad - any source change invalidates npm install
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm ci
RUN npm run build
```

### Multi-Stage Builds

Reduce final image size:

```dockerfile
# Build stage
FROM node:20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

### Security

```dockerfile
# Run as non-root
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
USER nextjs

# Don't expose secrets in build
# Use runtime environment variables instead
ENV DATABASE_URL=""
```

## Image Size Optimization

| Technique | Impact |
|-----------|--------|
| Alpine base images | ~5x smaller |
| Multi-stage builds | 2-10x smaller |
| `.dockerignore` | Faster builds |
| `--no-cache-dir` (pip) | Smaller Python images |
| `npm ci --omit=dev` | Smaller Node images |

## When NOT to Use Docker

| Scenario | Alternative |
|----------|-------------|
| Serverless functions | Native serverless packaging |
| Simple scripts | Direct execution |
| Local-only tools | Virtual environments |
| High-performance needs | Native binaries |

## Integration with Kubernetes

Docker images are typically deployed to Kubernetes:

```yaml
# Kubernetes deployment (separate from this template pack)
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
        - name: app
          image: myapp:1.0.0
```

## Registry Patterns

### Tagging Strategy

```bash
# Version tags
docker tag myapp:latest myapp:1.0.0
docker tag myapp:latest myapp:1.0
docker tag myapp:latest myapp:1

# Environment tags
docker tag myapp:latest myapp:staging
docker tag myapp:abc123 myapp:production
```

### Push to Registry

```bash
# Docker Hub
docker push username/myapp:1.0.0

# GitHub Container Registry
docker push ghcr.io/org/myapp:1.0.0

# AWS ECR
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:1.0.0
```

## Local Development

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgres://db:5432/app
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=app
      - POSTGRES_PASSWORD=dev
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

### Development Override

```yaml
# docker-compose.override.yml (auto-loaded)
version: '3.8'
services:
  app:
    volumes:
      - .:/app
    command: npm run dev
```

## Related Templates

- `.dockerignore`: `../ignore-files/dockerignore.template`
- Build caching: `../caching/build-cache-patterns.md`
- CI/CD: Out of scope (separate template pack)
