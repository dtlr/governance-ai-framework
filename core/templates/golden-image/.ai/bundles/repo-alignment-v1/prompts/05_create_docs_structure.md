# Prompt 05: Create Documentation Structure

## Context
AI artifacts created. Now create documentation structure.

## Task
Create `docs/_shared/` and routing infrastructure.

## Instructions

1. **Create directory structure**:
   ```bash
   mkdir -p docs/_shared
   mkdir -p docs/governance
   ```

2. **Create `docs/_shared/router.md`**:
   - Use template from golden-image as base
   - Customize directory mapping for this repo
   - Add intent→load routing table
   - Include project-specific sections

   **Required sections**:
   - Directory Purpose Map
   - Intent Routing Table
   - Load Targets
   - Quick Reference

3. **Create `docs/governance/GOVERNANCE_ROUTER.md`** (if applicable):
   - Links to governance submodule docs
   - Explains local vs submodule content
   - Maps governance concepts to repo usage

4. **Create `docs/_shared/DOC_STRATEGY.md`** (if missing):
   - Document organization principles
   - Canonical source definitions
   - Deduplication guidelines

5. **Create `AGENTS.md`** (if missing):
   - Human-readable project guide
   - More detailed than CLAUDE.md
   - Include workflows, examples, troubleshooting

## Router Content Requirements

The `router.md` must include:

```markdown
## Directory Purpose Map
| Directory | Purpose | When to Load |
|-----------|---------|--------------|
| [dir] | [description] | [trigger] |

## Intent Routing
| User Intent | Load Target |
|-------------|-------------|
| "How do I..." | [file] |

## Quick Reference
| Need | Load |
|------|------|
| [topic] | [path] |
```

## Completion
Say "Documentation structure created. Run prompt 06 to verify."
