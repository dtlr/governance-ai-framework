# Tooling Audit Bundle

**Mission**: Discover repo tooling and ensure documentation exists.

## When to Use

- Initial repo alignment
- After adding new tools
- Periodic audit

## Execution

```bash
# During alignment (automatic)
.governance/ai/core/automation/align-repo.sh

# Standalone audit
claude -p "$(cat .governance/ai/core/templates/golden-image/.ai/bundles/tooling-audit-v1/00_discover_tools.md)"
```

## Output

Creates/updates `.ai/TOOLING.md` with:
- Detected tools and their config files
- Links to official documentation
- Implementation status

## Known Tool Detection

| Tool | Config Files | Docs |
|------|--------------|------|
| EditorConfig | `.editorconfig` | https://editorconfig.org |
| direnv | `.envrc` | https://direnv.net |
| 1Password CLI | `op://` in .envrc | https://developer.1password.com/docs/cli |
| OpenTofu | `*.tf`, `.terraform.lock.hcl` | https://opentofu.org/docs |
| Helm | `Chart.yaml` | https://helm.sh/docs |
| Kustomize | `kustomization.yaml` | https://kustomize.io |
| ArgoCD | `*appset*.yml` | https://argo-cd.readthedocs.io |
| GitHub Actions | `.github/workflows/*.yml` | https://docs.github.com/actions |
| Make | `Makefile` | https://www.gnu.org/software/make/manual |
| Packer | `*.pkr.hcl` | https://developer.hashicorp.com/packer/docs |
| Claude Code | `.claude/` | https://docs.anthropic.com/claude-code |
| VSCode | `.vscode/` | https://code.visualstudio.com/docs |
| ESLint | `.eslintrc*` | https://eslint.org/docs |
| Prettier | `.prettierrc*` | https://prettier.io/docs |
| Biome | `biome.json` | https://biomejs.dev/reference |
| TypeScript | `tsconfig.json` | https://typescriptlang.org/docs |
| mise/asdf | `.mise.toml`, `.tool-versions` | https://mise.jdx.dev |
| pre-commit | `.pre-commit-config.yaml` | https://pre-commit.com |
| lefthook | `lefthook.yml` | https://github.com/evilmartians/lefthook |
| Ansible | `ansible.cfg`, `*.ansible/` | https://docs.ansible.com |
