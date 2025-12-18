# npm Scripts Patterns

## Purpose

Standard npm script patterns for JavaScript/TypeScript projects. Provides consistent commands across projects and integrates with CI/CD pipelines.

## Official Documentation

- [npm scripts](https://docs.npmjs.com/cli/using-npm/scripts) - Official reference
- [npm run-script](https://docs.npmjs.com/cli/commands/npm-run-script) - Run command docs
- [Life cycle scripts](https://docs.npmjs.com/cli/using-npm/scripts#life-cycle-scripts) - Pre/post hooks

## When to Use

- ✅ Any JavaScript/TypeScript project
- ✅ Projects using npm, yarn, pnpm, or bun
- ✅ CI/CD pipelines needing standard commands

## Standard Script Names

Use these conventional names for discoverability:

| Script | Purpose | Example |
|--------|---------|---------|
| `dev` | Start development server/mode | `next dev`, `vite` |
| `build` | Production build | `tsc`, `next build` |
| `start` | Run production server | `node dist/index.js` |
| `test` | Run test suite | `vitest`, `jest` |
| `lint` | Run linters | `eslint .` |
| `format` | Format code | `prettier --write .` |
| `typecheck` | Type checking (no emit) | `tsc --noEmit` |
| `clean` | Remove build artifacts | `rm -rf dist` |

## Template

### Node.js Application

```json
{
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "typecheck": "tsc --noEmit",
    "clean": "rm -rf dist coverage",
    "prepack": "npm run build"
  }
}
```

### React/Next.js Application

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "test": "vitest",
    "test:e2e": "playwright test",
    "lint": "next lint",
    "format": "prettier --write .",
    "typecheck": "tsc --noEmit",
    "clean": "rm -rf .next out coverage"
  }
}
```

### Library (npm package)

```json
{
  "scripts": {
    "build": "tsup",
    "dev": "tsup --watch",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "lint": "eslint .",
    "format": "prettier --write .",
    "typecheck": "tsc --noEmit",
    "clean": "rm -rf dist coverage",
    "prepublishOnly": "npm run build",
    "release": "npm run build && npm publish"
  }
}
```

### Monorepo Root

```json
{
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run dev",
    "test": "turbo run test",
    "lint": "turbo run lint",
    "format": "prettier --write .",
    "typecheck": "turbo run typecheck",
    "clean": "turbo run clean && rm -rf node_modules"
  }
}
```

## Script Patterns

### Chaining Commands

```json
{
  "scripts": {
    // Sequential (&&)
    "ci": "npm run lint && npm run test && npm run build",

    // Parallel (npm-run-all or &)
    "dev": "npm-run-all --parallel dev:*",
    "dev:server": "node server.js",
    "dev:watch": "tsc --watch"
  }
}
```

### Pre/Post Hooks

```json
{
  "scripts": {
    "prebuild": "npm run clean",
    "build": "tsc",
    "postbuild": "npm run copy-assets",

    "pretest": "npm run build",
    "test": "vitest",

    "prepublishOnly": "npm run build && npm test"
  }
}
```

### Environment Variables

```json
{
  "scripts": {
    // Inline (cross-platform issues)
    "build:prod": "NODE_ENV=production tsc",

    // Using cross-env (cross-platform)
    "build:prod": "cross-env NODE_ENV=production tsc",

    // Using dotenv
    "dev": "dotenv -e .env.local -- tsx src/index.ts"
  }
}
```

### Conditional Scripts

```json
{
  "scripts": {
    // Using npm-run-all for conditional
    "check": "run-s lint typecheck test",

    // CI-specific
    "ci": "npm run lint && npm run typecheck && npm run test:ci",
    "test:ci": "vitest run --coverage"
  }
}
```

## Common Script Groups

### Quality Checks

```json
{
  "scripts": {
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "typecheck": "tsc --noEmit",
    "check": "npm run lint && npm run typecheck && npm run format:check"
  }
}
```

### Testing

```json
{
  "scripts": {
    "test": "vitest",
    "test:watch": "vitest watch",
    "test:coverage": "vitest --coverage",
    "test:ci": "vitest run --reporter=junit --outputFile=test-results.xml",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui"
  }
}
```

### Database (if applicable)

```json
{
  "scripts": {
    "db:generate": "prisma generate",
    "db:push": "prisma db push",
    "db:migrate": "prisma migrate dev",
    "db:studio": "prisma studio",
    "db:seed": "tsx prisma/seed.ts"
  }
}
```

### Docker

```json
{
  "scripts": {
    "docker:build": "docker build -t myapp .",
    "docker:run": "docker run -p 3000:3000 myapp",
    "docker:push": "docker push myapp"
  }
}
```

## Package Manager Differences

| Feature | npm | yarn | pnpm | bun |
|---------|-----|------|------|-----|
| Run script | `npm run` | `yarn` | `pnpm` | `bun run` |
| Install | `npm install` | `yarn` | `pnpm install` | `bun install` |
| Run bin | `npx` | `yarn dlx` | `pnpm dlx` | `bunx` |

## Useful Utilities

### npm-run-all

Run multiple scripts in parallel or sequence:

```bash
npm install -D npm-run-all
```

```json
{
  "scripts": {
    "dev": "run-p dev:*",
    "dev:server": "node server.js",
    "dev:css": "postcss --watch",
    "check": "run-s lint typecheck test"
  }
}
```

### cross-env

Cross-platform environment variables:

```bash
npm install -D cross-env
```

```json
{
  "scripts": {
    "build:prod": "cross-env NODE_ENV=production webpack"
  }
}
```

### rimraf

Cross-platform rm -rf:

```bash
npm install -D rimraf
```

```json
{
  "scripts": {
    "clean": "rimraf dist coverage .next"
  }
}
```

### concurrently

Run commands concurrently with output prefix:

```bash
npm install -D concurrently
```

```json
{
  "scripts": {
    "dev": "concurrently \"npm:dev:*\"",
    "dev:server": "node server.js",
    "dev:watch": "tsc --watch"
  }
}
```

## CI/CD Integration

Scripts should work in CI without modification:

```json
{
  "scripts": {
    // ✅ Good - explicit, no interactive prompts
    "test:ci": "vitest run --reporter=junit",
    "build:ci": "npm run lint && npm run typecheck && npm run build",

    // ❌ Bad - interactive, watches
    "test": "vitest --watch"
  }
}
```

## Anti-Patterns

❌ **Avoid:**
```json
{
  "scripts": {
    // Too long - hard to read
    "build": "rm -rf dist && tsc && cp package.json dist/ && cd dist && npm pack",

    // Platform-specific
    "clean": "del /s /q dist",  // Windows only

    // No description possible
    "b": "npm run build"
  }
}
```

✅ **Prefer:**
```json
{
  "scripts": {
    "clean": "rimraf dist",
    "build": "npm run clean && tsc",
    "postbuild": "cp package.json dist/",
    "pack": "cd dist && npm pack"
  }
}
```

## Makefile Integration

Scripts can wrap or be wrapped by Make:

```makefile
# Makefile
.PHONY: build test lint

build:
	npm run build

test:
	npm test

lint:
	npm run lint
```

Or npm can call Make:

```json
{
  "scripts": {
    "build": "make build"
  }
}
```
