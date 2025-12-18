# Build Cache Patterns

## Purpose

General caching patterns for build systems across different languages and CI providers. Helps speed up builds by reusing previous work.

## Core Principles

1. **Deterministic inputs** → Same inputs produce same outputs
2. **Hash-based keys** → Cache key derived from input files
3. **Layered caching** → Multiple cache levels for different speeds
4. **Fallback keys** → Partial matches when exact key misses

## Cache Key Design

### Good Cache Keys

```yaml
# Exact match based on relevant files
key: build-${{ runner.os }}-${{ hashFiles('src/**', 'package.json') }}

# With version prefix for cache busting
key: v1-build-${{ hashFiles('src/**') }}

# Branch-aware for isolation
key: build-${{ github.ref_name }}-${{ hashFiles('src/**') }}
```

### Fallback Strategy

```yaml
key: build-${{ runner.os }}-${{ hashFiles('package-lock.json') }}
restore-keys: |
  build-${{ runner.os }}-
  build-
```

Order matters: most specific to least specific.

## By Language

### JavaScript/TypeScript

```yaml
# Dependencies
key: deps-${{ hashFiles('package-lock.json') }}
path: node_modules

# Build outputs (if not using Turbo)
key: build-${{ hashFiles('src/**', 'tsconfig.json') }}
path: dist
```

### Python

```yaml
# pip cache
key: pip-${{ hashFiles('requirements*.txt') }}
path: ~/.cache/pip

# virtualenv (optional)
key: venv-${{ hashFiles('requirements*.txt') }}
path: .venv
```

### Go

```yaml
# Module cache
key: go-mod-${{ hashFiles('go.sum') }}
path: ~/go/pkg/mod

# Build cache
key: go-build-${{ hashFiles('**/*.go') }}
path: ~/.cache/go-build
```

### Rust

```yaml
# Cargo cache
key: cargo-${{ hashFiles('Cargo.lock') }}
path: |
  ~/.cargo/bin
  ~/.cargo/registry
  ~/.cargo/git
  target
```

Or use dedicated action:
```yaml
- uses: Swatinem/rust-cache@v2
```

## By CI Provider

### GitHub Actions

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cache
    key: cache-${{ hashFiles('**/*.txt') }}
    restore-keys: cache-
```

### GitLab CI

```yaml
cache:
  key:
    files:
      - package-lock.json
  paths:
    - node_modules/
```

### CircleCI

```yaml
- restore_cache:
    keys:
      - deps-{{ checksum "package-lock.json" }}
      - deps-
- save_cache:
    key: deps-{{ checksum "package-lock.json" }}
    paths:
      - node_modules
```

### Azure Pipelines

```yaml
- task: Cache@2
  inputs:
    key: 'npm | "$(Agent.OS)" | package-lock.json'
    path: $(npm_config_cache)
```

## Docker Layer Caching

### In CI/CD

```yaml
# GitHub Actions with BuildKit
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### In Dockerfile

```dockerfile
# Order layers by change frequency (stable first)
FROM node:20-alpine

# 1. Dependencies (changes sometimes)
COPY package*.json ./
RUN npm ci

# 2. Source (changes often)
COPY . .
RUN npm run build
```

## Incremental Build Caching

### TypeScript

```json
// tsconfig.json
{
  "compilerOptions": {
    "incremental": true,
    "tsBuildInfoFile": ".tsbuildinfo"
  }
}
```

Cache the `.tsbuildinfo` file.

### Webpack

```javascript
// webpack.config.js
module.exports = {
  cache: {
    type: 'filesystem',
    cacheDirectory: '.webpack-cache'
  }
};
```

### Vite

Vite caches by default in `node_modules/.vite`.

## Monorepo Patterns

### Turbo (Recommended)

```json
// turbo.json
{
  "tasks": {
    "build": {
      "outputs": ["dist/**"],
      "cache": true
    }
  }
}
```

With remote cache:
```yaml
env:
  TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
  TURBO_TEAM: ${{ vars.TURBO_TEAM }}
```

### Nx

```json
// nx.json
{
  "tasksRunnerOptions": {
    "default": {
      "runner": "nx/tasks-runners/default",
      "options": {
        "cacheableOperations": ["build", "test", "lint"]
      }
    }
  }
}
```

## Cache Invalidation

### Manual Invalidation

```yaml
# Bump version in key
key: v2-deps-${{ hashFiles('package-lock.json') }}
```

### Time-Based Invalidation

```yaml
# Include date for daily refresh
key: deps-${{ hashFiles('lock') }}-${{ steps.date.outputs.date }}

- id: date
  run: echo "date=$(date +%Y-%m-%d)" >> $GITHUB_OUTPUT
```

### Conditional Caching

```yaml
# Only save on main branch
- uses: actions/cache/save@v4
  if: github.ref == 'refs/heads/main'
```

## Measuring Effectiveness

### Metrics to Track

| Metric | Target |
|--------|--------|
| Cache hit rate | > 80% |
| Time saved per hit | Measurable improvement |
| Cache size | Within limits |

### GitHub Actions

```yaml
# Cache action outputs hit status
- uses: actions/cache@v4
  id: cache
  with:
    path: node_modules
    key: deps-${{ hashFiles('package-lock.json') }}

- if: steps.cache.outputs.cache-hit != 'true'
  run: npm ci
```

## Common Issues

### Cache Too Large

```yaml
# Exclude unnecessary files
path: |
  node_modules
  !node_modules/.cache
```

### Cache Not Helping

1. Check hit rate in logs
2. Verify key is stable
3. Ensure restore-keys allow fallback
4. Check cache isn't expired

### Stale Cache

1. Increment version prefix: `v1-` → `v2-`
2. Add more files to hash
3. Use shorter cache lifetime

## Best Practices

1. **Hash lock files, not manifests**
   - `package-lock.json` not `package.json`
   - More precise cache invalidation

2. **Include OS/arch in key**
   - Native dependencies vary by platform

3. **Use fallback keys**
   - Partial cache better than none

4. **Layer appropriately**
   - Separate deps from build outputs
   - Deps change less often

5. **Monitor and tune**
   - Track hit rates
   - Adjust key strategy based on data
