# Build & Dependency Caching

## Overview

Caching strategies for faster builds and CI/CD pipelines. Covers build caches, dependency caches, and remote caching.

## Quick Reference

| Cache Type | Tool | Benefit |
|------------|------|---------|
| Build cache | Turbo, Nx | Skip unchanged builds |
| Dependency cache | npm, pip | Skip package downloads |
| Docker layer cache | Docker | Reuse build layers |
| Remote cache | Turbo, Nx | Share cache across machines |

## Template Hierarchy

```
caching/
├── README.md               # This file
├── turbo-cache.md         # Turborepo caching
├── npm-cache.md           # npm/pnpm/yarn caching
└── build-cache-patterns.md # General patterns
```

## Caching Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     Remote Cache                             │
│         (Turbo Remote, Nx Cloud, GitHub Actions Cache)       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Build Cache                              │
│              (Turbo, Nx, incremental builds)                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Dependency Cache                           │
│           (node_modules, pip cache, go mod cache)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Docker Layer Cache                         │
│              (reuse unchanged image layers)                  │
└─────────────────────────────────────────────────────────────┘
```

## When to Implement Caching

| Symptom | Solution |
|---------|----------|
| CI takes >5 min | Add dependency caching |
| `npm install` slow | Use npm cache in CI |
| Building unchanged code | Use Turbo/Nx build cache |
| Team waiting on builds | Add remote caching |
| Docker builds slow | Optimize layer caching |

## Stack-Specific Caching

### JavaScript/Node.js

```yaml
# GitHub Actions
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: npm-${{ hashFiles('**/package-lock.json') }}
```

See: `npm-cache.md`

### Monorepo (Turbo)

```json
// turbo.json
{
  "tasks": {
    "build": {
      "outputs": ["dist/**"]
    }
  }
}
```

See: `turbo-cache.md`

### Python

```yaml
# GitHub Actions
- uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: pip-${{ hashFiles('**/requirements*.txt') }}
```

### Go

```yaml
# GitHub Actions
- uses: actions/cache@v4
  with:
    path: |
      ~/go/pkg/mod
      ~/.cache/go-build
    key: go-${{ hashFiles('**/go.sum') }}
```

### Rust

```yaml
# GitHub Actions
- uses: Swatinem/rust-cache@v2
```

### Docker

See: `../docker/dockerfile-patterns.md` for layer caching

## CI/CD Cache Strategies

### Cache by Lockfile Hash

Most common pattern - cache key based on dependency lockfile:

```yaml
key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
restore-keys: |
  ${{ runner.os }}-npm-
```

### Cache with Fallback

```yaml
key: npm-exact-${{ hashFiles('package-lock.json') }}
restore-keys: |
  npm-exact-
  npm-
```

### Branch-Based Caching

```yaml
key: build-${{ github.ref_name }}-${{ hashFiles('src/**') }}
restore-keys: |
  build-${{ github.ref_name }}-
  build-main-
  build-
```

## Cache Invalidation

| Event | Action |
|-------|--------|
| Lock file changed | Cache miss, rebuild |
| Source changed | Build cache miss (Turbo handles) |
| Cache expired | Rebuild from scratch |
| Manual trigger | `turbo run build --force` |

## Measuring Cache Effectiveness

### Turbo Statistics

```bash
turbo run build --summarize
```

Shows cache hit rate, time saved.

### CI Time Tracking

Track before/after:
- Time to install dependencies
- Time to build
- Total workflow time

## Trade-offs

| Approach | Pros | Cons |
|----------|------|------|
| Local cache | Fast, no setup | Not shared |
| Remote cache | Shared, persistent | Setup required, cost |
| CI cache | Shared within CI | Limited to CI provider |
| No cache | Simple, always fresh | Slow builds |

## Common Issues

### Cache Growing Too Large

```bash
# Clear Turbo cache
turbo prune

# Clear npm cache
npm cache clean --force

# GitHub Actions has 10GB limit
# Use cache eviction or cleanup
```

### Stale Cache

```bash
# Force fresh build
turbo run build --force
npm ci  # (not npm install)
```

### Cache Key Misses

Check that:
- Hash includes all relevant files
- OS/arch matches between save/restore
- Branch strategy allows fallback

## Related Documentation

- Turbo cache: `turbo-cache.md`
- npm cache: `npm-cache.md`
- General patterns: `build-cache-patterns.md`
- Docker layers: `../docker/dockerfile-patterns.md`
