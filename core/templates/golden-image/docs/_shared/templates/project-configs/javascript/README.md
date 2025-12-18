# JavaScript/TypeScript Configuration Templates

## Overview

Configuration templates for JavaScript and TypeScript projects, covering linting, formatting, compilation, and monorepo tooling.

## Detection

**Marker Files:**
- `package.json` → JavaScript/Node.js project
- `tsconfig.json` → TypeScript project
- `turbo.json` → Turborepo monorepo

**Load When:** Any of these markers exist

## Template Hierarchy

```
javascript/
├── README.md           # This file
├── eslint.template     # ESLint 9+ flat config
├── prettier.template   # Prettier configuration
├── tsconfig.template   # TypeScript compiler options
├── turbo.template      # Turborepo pipeline (monorepos)
└── package-scripts.md  # npm scripts patterns
```

## Quick Reference

| Config | Purpose | Required When |
|--------|---------|---------------|
| `eslint.config.js` | Code linting | Any JS/TS project |
| `.prettierrc` | Code formatting | Any JS/TS project |
| `tsconfig.json` | TypeScript compilation | TypeScript files exist |
| `turbo.json` | Monorepo builds | Multiple packages |

## Config Loading Order

For new JavaScript/TypeScript projects:

1. **Always load:** `eslint.template`, `prettier.template`
2. **If TypeScript:** Add `tsconfig.template`
3. **If monorepo:** Add `turbo.template`
4. **Always review:** `package-scripts.md` for npm scripts

## Integration Points

### ESLint + Prettier

These tools can conflict. Use one of these approaches:

**Option A: Prettier as ESLint rule** (Recommended)
```javascript
// eslint.config.js
import prettier from "eslint-plugin-prettier";

export default [
  // ... other config
  {
    plugins: { prettier },
    rules: {
      "prettier/prettier": "error"
    }
  }
];
```

**Option B: Separate tools**
- Run Prettier first (format)
- Run ESLint second (lint)
- ESLint ignores formatting rules

### TypeScript + ESLint

Use `typescript-eslint` for type-aware linting:

```javascript
// eslint.config.js
import tseslint from "typescript-eslint";

export default tseslint.config(
  // Enables type-aware linting
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        project: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  }
);
```

### Turbo + npm Scripts

Turbo wraps npm scripts for caching and parallelization:

```json
// turbo.json
{
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    }
  }
}
```

```bash
# Runs npm run build in all packages with caching
turbo run build
```

## Common Patterns

### Single Package Project
```
project/
├── package.json        # Scripts: build, test, lint
├── eslint.config.js    # Flat config
├── .prettierrc         # Formatting rules
├── tsconfig.json       # If TypeScript
└── src/
```

### Monorepo with Turbo
```
monorepo/
├── package.json        # Root workspace
├── turbo.json          # Pipeline config
├── eslint.config.js    # Shared ESLint (root)
├── .prettierrc         # Shared Prettier (root)
├── tsconfig.json       # Base TypeScript config
├── packages/
│   ├── shared/
│   │   ├── package.json
│   │   └── tsconfig.json  # Extends root
│   └── app/
│       ├── package.json
│       └── tsconfig.json  # Extends root
└── apps/
    └── web/
        ├── package.json
        └── tsconfig.json
```

## Package Manager Notes

| Manager | Lock File | Config |
|---------|-----------|--------|
| npm | `package-lock.json` | `.npmrc` |
| yarn | `yarn.lock` | `.yarnrc.yml` |
| pnpm | `pnpm-lock.yaml` | `.npmrc` or `pnpm-workspace.yaml` |
| bun | `bun.lockb` | `bunfig.toml` |

## When NOT to Use These Templates

| Scenario | Skip These |
|----------|------------|
| Shell scripts only | All JavaScript configs |
| Python project | All JavaScript configs |
| Using Biome instead | ESLint + Prettier (use Biome config) |
| Single small script | Full toolchain (use minimal setup) |

## Alternatives

| Tool | Alternative | When to Consider |
|------|-------------|------------------|
| ESLint + Prettier | [Biome](https://biomejs.dev/) | Faster, single tool |
| npm | pnpm, yarn, bun | Better monorepo support, speed |
| Turbo | [Nx](https://nx.dev/) | More features, different DX |
| TypeScript | No types | Very small projects |

## Version Notes

- **ESLint 9+**: Uses flat config (`eslint.config.js`), not `.eslintrc.*`
- **TypeScript 5+**: Project references for monorepos
- **Node 18+**: Native fetch, test runner, ESM by default
