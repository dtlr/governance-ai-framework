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

## Never Do This

❌ `tofu apply` without `-out` flag
❌ `tofu apply -auto-approve` in production
❌ Skip validation scripts
❌ Commit without updating state cache
❌ Apply without reviewing plan first
❌ Apply to production from feature branch
