# npm/pnpm/yarn Dependency Caching

## Purpose

Cache Node.js dependencies in CI/CD pipelines to avoid re-downloading packages on every build.

## Official Documentation

- [npm cache](https://docs.npmjs.com/cli/cache) - npm cache commands
- [pnpm store](https://pnpm.io/cli/store) - pnpm content-addressable store
- [yarn cache](https://yarnpkg.com/cli/cache) - yarn cache management
- [GitHub Actions cache](https://github.com/actions/cache) - CI caching

## When to Use

- ✅ Any Node.js project in CI/CD
- ✅ Slow `npm install` in pipelines
- ✅ Repeated builds with same dependencies

## When NOT to Use

- ❌ Local development (already cached)
- ❌ Very fast CI (caching overhead may not help)

## Cache Locations

| Package Manager | Cache Path |
|-----------------|------------|
| npm | `~/.npm` |
| pnpm | `~/.pnpm-store` |
| yarn | `~/.cache/yarn` or `.yarn/cache` |
| bun | `~/.bun/install/cache` |

## GitHub Actions

### npm

```yaml
name: CI

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci
      - run: npm test
```

### pnpm

```yaml
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

      - run: pnpm install --frozen-lockfile
      - run: pnpm test
```

### yarn

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'yarn'

      - run: yarn install --frozen-lockfile
      - run: yarn test
```

### Manual Cache Configuration

For more control:

```yaml
- name: Cache node_modules
  uses: actions/cache@v4
  with:
    path: node_modules
    key: node-modules-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      node-modules-${{ runner.os }}-

- name: Install dependencies
  run: npm ci
```

### Cache Both Store and node_modules

```yaml
- name: Get pnpm store directory
  id: pnpm-cache
  run: echo "STORE_PATH=$(pnpm store path)" >> $GITHUB_OUTPUT

- name: Cache pnpm store
  uses: actions/cache@v4
  with:
    path: ${{ steps.pnpm-cache.outputs.STORE_PATH }}
    key: pnpm-store-${{ runner.os }}-${{ hashFiles('**/pnpm-lock.yaml') }}
    restore-keys: |
      pnpm-store-${{ runner.os }}-

- name: Cache node_modules
  uses: actions/cache@v4
  with:
    path: node_modules
    key: node-modules-${{ runner.os }}-${{ hashFiles('**/pnpm-lock.yaml') }}
```

## GitLab CI

```yaml
# .gitlab-ci.yml
cache:
  key:
    files:
      - package-lock.json
  paths:
    - node_modules/
    - .npm/

before_script:
  - npm ci --cache .npm --prefer-offline
```

## CircleCI

```yaml
# .circleci/config.yml
version: 2.1
jobs:
  build:
    docker:
      - image: node:20
    steps:
      - checkout
      - restore_cache:
          keys:
            - npm-deps-{{ checksum "package-lock.json" }}
            - npm-deps-
      - run: npm ci
      - save_cache:
          key: npm-deps-{{ checksum "package-lock.json" }}
          paths:
            - ~/.npm
```

## Best Practices

### Use `npm ci` Not `npm install`

```bash
# Good - uses lockfile exactly, faster
npm ci

# Bad - may update lockfile
npm install
```

### Hash the Right File

| Manager | Hash File |
|---------|-----------|
| npm | `package-lock.json` |
| pnpm | `pnpm-lock.yaml` |
| yarn | `yarn.lock` |

### Include OS in Cache Key

```yaml
key: deps-${{ runner.os }}-${{ hashFiles('package-lock.json') }}
```

Different OS may have different native bindings.

### Use Fallback Keys

```yaml
restore-keys: |
  deps-${{ runner.os }}-${{ hashFiles('package-lock.json') }}
  deps-${{ runner.os }}-
  deps-
```

Allows partial cache hits when lockfile changes slightly.

## Cache Strategies

### Strategy 1: Cache Store Only

```yaml
# Cache the download cache, not node_modules
# Pro: Smaller cache, always runs npm ci
# Con: Still runs npm ci every time
path: ~/.npm
```

### Strategy 2: Cache node_modules

```yaml
# Cache installed dependencies
# Pro: Fastest when unchanged
# Con: Larger cache, may have stale deps
path: node_modules
```

### Strategy 3: Both

```yaml
# Cache both for best performance
path: |
  ~/.npm
  node_modules
```

## Monorepo Caching

### With Workspaces

```yaml
- uses: actions/cache@v4
  with:
    path: |
      **/node_modules
      ~/.npm
    key: deps-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
```

### With Turbo

Turbo handles its own caching. For dependencies:

```yaml
- uses: actions/setup-node@v4
  with:
    cache: 'pnpm'
    cache-dependency-path: '**/pnpm-lock.yaml'
```

## Debugging Cache Issues

### Check Cache Size

```bash
# npm
npm cache ls

# pnpm
pnpm store status

# Check node_modules size
du -sh node_modules
```

### Clear Cache

```bash
# npm
npm cache clean --force

# pnpm
pnpm store prune

# yarn
yarn cache clean
```

### GitHub Actions Cache Limits

- Maximum cache size: 10 GB per repo
- Caches not accessed in 7 days are evicted
- Check cache usage in Actions → Caches

## Troubleshooting

### Cache Not Restoring

1. Check key matches exactly
2. Verify path is correct
3. Check cache hasn't expired (7 days)

### Cache Too Large

```yaml
# Only cache necessary directories
path: |
  ~/.npm
  # Don't cache all of node_modules
```

### Stale Dependencies

```bash
# Force clean install
rm -rf node_modules
npm ci
```

Or use `npm ci` which always does clean install.
