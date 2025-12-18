# Tooling Discovery

Scan this repository for tooling configuration and create `.ai/TOOLING.md`.

## Instructions

1. Search for these config files:
   - `.editorconfig` → EditorConfig
   - `.envrc` → direnv (check for `op://` = 1Password)
   - `*.tf` → OpenTofu/Terraform
   - `Chart.yaml` → Helm
   - `kustomization.yaml` → Kustomize
   - `.github/workflows/*.yml` → GitHub Actions
   - `Makefile` → Make
   - `*.pkr.hcl` → Packer
   - `.claude/` → Claude Code
   - `.vscode/` → VSCode
   - `.eslintrc*` → ESLint
   - `.prettierrc*` → Prettier
   - `biome.json` → Biome
   - `tsconfig.json` → TypeScript
   - `.mise.toml` or `.tool-versions` → mise/asdf
   - `.pre-commit-config.yaml` → pre-commit
   - `lefthook.yml` → lefthook
   - `ansible.cfg` or `.ansible/` → Ansible

2. For each discovered tool, note:
   - Config file location
   - Current configuration summary
   - Whether it's properly configured

3. Create `.ai/TOOLING.md` with format:

```markdown
# Repository Tooling

## Detected Tools

| Tool | Config | Status | Docs |
|------|--------|--------|------|
| EditorConfig | `.editorconfig` | ✓ | [Docs](https://editorconfig.org) |
| direnv | `.envrc` | ✓ | [Docs](https://direnv.net) |
...

## Tool Details

### EditorConfig
- **Config**: `.editorconfig`
- **Purpose**: Consistent formatting across editors
- **Docs**: https://editorconfig.org
- **Status**: ✓ Configured

### direnv
- **Config**: `.envrc`
- **Purpose**: Directory-specific environment variables
- **Integrations**: 1Password CLI (`op://` secrets)
- **Docs**: https://direnv.net
- **Status**: ✓ Configured

...

## Missing/Recommended

| Tool | Purpose | Docs |
|------|---------|------|
| pre-commit | Git hooks | https://pre-commit.com |
```

4. Flag any tools that appear misconfigured or have outdated patterns.
