# Turborepo Caching

## Purpose

Turborepo's caching system stores task outputs and skips re-execution when inputs haven't changed. Works locally and can be shared across teams with remote caching.

## Official Documentation

- [Caching Tasks](https://turbo.build/repo/docs/core-concepts/caching) - How caching works
- [Remote Caching](https://turbo.build/repo/docs/core-concepts/remote-caching) - Team cache sharing
- [Configuration](https://turbo.build/repo/docs/reference/configuration) - turbo.json reference

## When to Use

- ✅ Monorepos with multiple packages
- ✅ Projects wanting faster rebuilds
- ✅ Teams wanting shared build cache

## When NOT to Use

- ❌ Single-package projects (minimal benefit)
- ❌ Projects without repeated builds
- ❌ Sensitive builds that can't use remote cache

## How It Works

```
Task Request: turbo run build
        │
        ▼
┌───────────────────┐
│ Compute Input Hash│  (source files, deps, env vars)
└───────────────────┘
        │
        ▼
┌───────────────────┐     Cache Hit
│ Check Local Cache │ ──────────────► Restore outputs, skip task
└───────────────────┘
        │ Cache Miss
        ▼
┌───────────────────┐     Cache Hit
│ Check Remote Cache│ ──────────────► Download, restore, skip task
└───────────────────┘
        │ Cache Miss
        ▼
┌───────────────────┐
│   Execute Task    │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│  Save to Cache(s) │
└───────────────────┘
```

## Configuration

### Basic Setup

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**"]
    },
    "test": {
      "outputs": ["coverage/**"]
    },
    "lint": {
      "outputs": []
    }
  }
}
```

### With Environment Variables

Environment variables affect cache keys:

```json
{
  "globalEnv": ["CI", "NODE_ENV"],
  "tasks": {
    "build": {
      "outputs": ["dist/**"],
      "env": ["API_URL", "PUBLIC_*"]
    }
  }
}
```

### Cache Inputs

By default, all files in the package are inputs. Customize:

```json
{
  "tasks": {
    "build": {
      "inputs": [
        "src/**",
        "package.json",
        "tsconfig.json"
      ],
      "outputs": ["dist/**"]
    }
  }
}
```

### Disabling Cache

For tasks that shouldn't cache:

```json
{
  "tasks": {
    "dev": {
      "cache": false,
      "persistent": true
    },
    "deploy": {
      "cache": false
    }
  }
}
```

## Remote Caching

### Setup with Vercel

```bash
# Login (free tier available)
turbo login

# Link to Vercel
turbo link
```

### In CI/CD

```yaml
# GitHub Actions
env:
  TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
  TURBO_TEAM: ${{ vars.TURBO_TEAM }}

- run: pnpm turbo run build
```

### Self-Hosted Remote Cache

Use `turbo --api` flag or configure:

```json
// turbo.json
{
  "remoteCache": {
    "signature": true,
    "enabled": true
  }
}
```

## Cache Commands

```bash
# Run with cache (default)
turbo run build

# Force fresh run (ignore cache)
turbo run build --force

# Dry run (show what would happen)
turbo run build --dry-run

# Show cache statistics
turbo run build --summarize

# Clear local cache
turbo prune
```

## Debugging Cache

### Check Cache Status

```bash
# See cache hits/misses
turbo run build --summarize

# Output includes:
# - Hash of each task
# - Whether it was cached
# - Time saved
```

### Why Cache Miss?

Common reasons:
1. **Source files changed** - Expected behavior
2. **Dependencies changed** - Package was rebuilt
3. **Environment variable changed** - Check `env` and `globalEnv`
4. **Config changed** - turbo.json, package.json
5. **First run** - No cache exists yet

### Verbose Output

```bash
turbo run build --verbosity=2
```

## Output Configuration

### Include Specific Files

```json
{
  "tasks": {
    "build": {
      "outputs": [
        "dist/**",
        "!dist/**/*.map"  // Exclude source maps
      ]
    }
  }
}
```

### Framework-Specific

**Next.js:**
```json
{
  "outputs": [".next/**", "!.next/cache/**"]
}
```

**Vite:**
```json
{
  "outputs": ["dist/**"]
}
```

**TypeScript:**
```json
{
  "outputs": ["dist/**", "*.tsbuildinfo"]
}
```

## Best Practices

### 1. Declare All Outputs

```json
// Good - all outputs declared
{
  "build": {
    "outputs": ["dist/**", "types/**"]
  }
}

// Bad - missing outputs won't be cached
{
  "build": {
    "outputs": ["dist/**"]
    // types/** missing!
  }
}
```

### 2. Declare Environment Variables

```json
// Good - env vars in cache key
{
  "build": {
    "env": ["API_URL", "NODE_ENV"]
  }
}

// Bad - different API_URL produces same cache
{
  "build": {
    "outputs": ["dist/**"]
    // env not declared
  }
}
```

### 3. Use Granular Tasks

```json
// Good - separate cacheable tasks
{
  "typecheck": { "outputs": [] },
  "build": { "outputs": ["dist/**"] },
  "test": { "outputs": ["coverage/**"] }
}

// Bad - one big task
{
  "ci": { "outputs": ["dist/**", "coverage/**"] }
}
```

## CI/CD Integration

### GitHub Actions

```yaml
name: CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'

      - run: pnpm install

      - run: pnpm turbo run build test lint
        env:
          TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
          TURBO_TEAM: ${{ vars.TURBO_TEAM }}
```

### Cache Hit Rate Goals

| Rate | Status |
|------|--------|
| < 50% | Review outputs and env config |
| 50-80% | Good, some room for improvement |
| > 80% | Excellent |

## Troubleshooting

### Cache Always Misses

1. Check `env` includes all build-affecting vars
2. Verify `outputs` are correct
3. Run `--summarize` to see hash inputs
4. Ensure `.gitignore` doesn't exclude cached files

### Remote Cache Slow

1. Check network connectivity
2. Consider output size (large outputs = slow upload)
3. Exclude unnecessary files from outputs

### Local Cache Too Large

```bash
# Clear old cache entries
turbo prune

# Check cache size
du -sh node_modules/.cache/turbo
```
