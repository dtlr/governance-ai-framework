# IaC Deployment Safety

## Saved Plans (Critical Rule)

**YOU MUST** always use saved plans for all applies:

```bash
# CORRECT
tofu plan -out=tofu.plan
tofu apply tofu.plan

# WRONG - Never do this
tofu apply
tofu apply -auto-approve
```

### Why

- **Review**: Plans can be reviewed before applying
- **Audit**: Plans provide record of intended changes
- **Safety**: Prevents accidental applies with stale state
- **CI/CD**: Plans can be generated in one step, applied in another

## Validation Before Operations

**YOU MUST** validate environment before every tofu operation:

```bash
# Run validation first
./scripts/validate_env.sh

# Then proceed
tofu plan -out=tofu.plan
```

### What Validation Checks

- In correct git repository
- On correct git branch
- Required environment variables loaded
- Module-specific credentials present
- tofu binary available
- Module initialized (.terraform directory exists)

## Module Execution Safety

**ALWAYS** use safe execution wrappers:

```bash
# Use wrapper script
./scripts/in_module.sh <module> tofu plan

# NOT direct cd
cd module && tofu plan  # WRONG - no cleanup guarantee
```

### Wrapper Benefits

- Guaranteed return to original directory
- Environment variable loading via direnv
- Error handling and reporting
- Consistent execution pattern

## State Cache Updates

**YOU MUST** update state cache after every apply:

```bash
tofu apply tofu.plan
./scripts/update_state_cache.sh  # REQUIRED
```

### Why

- AI assistants need current resource inventory
- 40-60% token reduction from cached state
- Team visibility into infrastructure
- Documentation stays current

## Command-to-Path Mapping (CRITICAL)

Every command has a required execution path. **VERIFY BEFORE EXECUTING.**

| Command | Required Path | Verify With |
|---------|---------------|-------------|
| `tofu plan` | Module directory | `ls main.tf` |
| `tofu apply` | Module directory | `ls main.tf` |
| `tofu state list` | Module directory | `ls .terraform/` |
| `tofu init` | Module directory | `ls *.tf` |
| `./scripts/in_module.sh` | Repo root | `ls scripts/in_module.sh` |
| `./scripts/validate_env.sh` | Repo root OR module | `ls ../scripts/` or `ls scripts/` |
| `./scripts/update_state_cache.sh` | Repo root | `ls STATE_CACHE*.md` |
| `./scripts/update_governance.sh` | Repo root | `ls .governance/` |
| `git submodule update` | Repo root | `ls .gitmodules` |
| `direnv allow` | Directory with `.envrc` | `ls .envrc` |

### Path Requirements by Operation Type

```
REPO ROOT (/home/user/tf-msvcs/)
├── Run: ./scripts/*.sh
├── Run: git submodule commands
├── Run: ./scripts/in_module.sh <module> <cmd>
│
├── MODULE DIRECTORY (/home/user/tf-msvcs/<module>/)
│   ├── Run: tofu plan/apply/init/state
│   ├── Run: ../scripts/validate_env.sh
│   └── Verify: ls main.tf .terraform/
│
└── SUBMODULE DIRECTORY (.governance/ai/)
    ├── Run: git checkout <tag> (via git -C from root)
    └── NEVER: cd here then modify parent
```

### Pre-Execution Checklist

Before ANY tofu command:
```bash
# 1. Am I in the right place?
pwd                              # Must be module directory
ls main.tf                       # Must exist

# 2. Is module initialized?
ls .terraform/                   # Must exist

# 3. Are credentials loaded?
echo $DIGITALOCEAN_TOKEN         # Must be set (or appropriate var)
```

## Path Verification (CRITICAL)

**YOU MUST** verify working directory before ANY tofu command:

```bash
# Pre-flight check pattern
pwd                              # Verify expected path
git rev-parse --show-toplevel    # Verify in correct repo
ls .terraform/                   # Verify module initialized
tofu plan -out=tofu.plan         # NOW safe to execute
```

### Why Path Matters

- Running tofu from wrong directory = wrong state file = DISASTER
- Shell can become "stuck" in non-existent path after directory operations
- Relative paths (`../..`) can resolve incorrectly after `cd` commands

### Safe Patterns

```bash
# CORRECT - Use wrapper (handles all safety)
./scripts/in_module.sh 0-digitalocean tofu plan -out=tofu.plan

# CORRECT - Use absolute paths
cd /home/user/repo/module && tofu plan

# CORRECT - Use git -C for submodule operations
git -C .governance/ai checkout v1.0.1

# WRONG - Relative paths after cd
cd ../module && tofu plan

# WRONG - cd into directory then modify it
cd .governance/ai
mv ../ai ../ai.bak  # Shell now orphaned!
```

## Shell Recovery

If shell becomes "stuck" (commands fail with "no such directory"):

```bash
# Escape with absolute path
cd /home/user/repo

# Or start fresh shell
exec $SHELL

# Re-initialize broken submodule
git submodule update --init --force .governance/ai
```

## Never Do This

❌ `tofu apply` without `-out` flag
❌ `tofu apply -auto-approve` in production
❌ Skip validation scripts
❌ Commit without updating state cache
❌ Apply without reviewing plan first
❌ Apply to production from feature branch
❌ Run tofu without verifying working directory first
❌ Use relative paths for critical operations
❌ `cd` into a directory before operations that move/delete it
