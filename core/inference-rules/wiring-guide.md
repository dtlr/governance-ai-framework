# Inference: Wiring Guide for Lazy Loading System

## Intent

Practical step-by-step guide for connecting the lazy loading system components. Shows HOW to wire manifest.json, router.md, CLAUDE.md hierarchy, and inference rules together.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        GOVERNANCE SUBMODULE                              │
│  .governance/ai/                                                         │
│  ├── manifest.json         ← Discovery protocol (entrypoints, paths)    │
│  ├── 00_INDEX/             ← Entry point docs                           │
│  └── core/inference-rules/ ← Behavioral rules (lazy-loading, tiers)     │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ References
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        REPO-OWNED FILES                                  │
│  /                                                                       │
│  ├── CLAUDE.md             ← Tier 1: Root context (always loaded)       │
│  ├── docs/_shared/router.md ← Routing map (repo-specific triggers)      │
│  ├── .ai/                  ← Instance lifecycle (ledger, scratch)       │
│  │   └── inference/        ← Repo-local inference overrides             │
│  └── <modules>/CLAUDE.md   ← Tier 2: Module contexts (lazy)             │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Component Connections

### 1. manifest.json → Everything

The manifest is the discovery protocol. AI reads it first to understand what to load.

```json
{
  "governance_root": ".governance/ai",
  "entrypoints": [
    ".governance/ai/00_INDEX/README.md",  // Global governance entry
    "CLAUDE.md"                            // Repo root context (Tier 1)
  ],
  "optional_context": [
    "AGENTS.md",                           // Tier 3 (load on demand)
    "docs/_shared/",                       // Router + shared docs
    ".ai/ledger/LEDGER.md"                // Operations history
  ],
  "ai_artifacts": {
    "root": ".ai",
    "scratch": ".ai/_scratch",
    "ledger": ".ai/ledger/LEDGER.md"
  }
}
```

**Wiring rules:**
- `entrypoints` are ALWAYS loaded (Tier 1)
- `optional_context` are loaded on-demand (Tier 2/3)
- `ai_artifacts` tells AI where to write working files

### 2. CLAUDE.md → router.md

Root CLAUDE.md should reference the router for navigation:

```markdown
## Read Order
1. This file (CLAUDE.md) - Repository context
2. `.governance/ai/` - Governance framework (submodule)
3. `docs/_shared/router.md` - Navigation map ← POINTER TO ROUTER
4. Module-specific `CLAUDE.md` files as needed
```

### 3. router.md → Inference Rules + Docs

Router contains triggers that tell AI when to load what:

```markdown
## Routing triggers

- If asked about **file cleanup / lifecycle**:
  - Load: `.governance/ai/core/inference-rules/file-lifecycle.md`

- If asked about **context loading / tiers**:
  - Load: `.governance/ai/core/inference-rules/three-tier-system.md`
  - Load: `.governance/ai/core/inference-rules/lazy-loading.md`

- If asked about **cost optimization**:
  - Load: `.governance/ai/core/inference-rules/cost-optimization.md`
```

### 4. Module CLAUDE.md → Root CLAUDE.md

Each module CLAUDE.md should reference back to root:

```markdown
# <Module> CLAUDE.md

## Read Order
1. Root `CLAUDE.md` (required first)  ← POINTER BACK TO ROOT
2. This file (module context)
3. `AGENTS.md` (if detailed understanding needed)
```

---

## Step-by-Step Wiring

### Step 1: Set Up Governance Submodule

```bash
# Add governance as submodule
git submodule add git@github.com:org/governance-ai-framework.git .governance/ai

# Create wrapper
mkdir -p .governance
cat > .governance/manifest.json << 'EOF'
{
  "governance_root": ".governance/ai",
  "entrypoints": [
    ".governance/ai/00_INDEX/README.md",
    "CLAUDE.md"
  ],
  "optional_context": [
    "AGENTS.md",
    "docs/_shared/"
  ]
}
EOF
```

### Step 2: Create Root CLAUDE.md (Tier 1)

```markdown
# CLAUDE.md - <Project Name>

This file provides AI operating constraints for <project>.

## Read Order
1. This file (CLAUDE.md) - Repository context
2. `.governance/ai/` - Governance framework
3. `docs/_shared/router.md` - Navigation map
4. Module-specific `CLAUDE.md` files

## Repository Purpose
<1-2 sentences>

## Repository Structure
```
<tree structure with module descriptions>
```

## Technology Stack
<list of key technologies>

## Operating Constraints
<critical rules - deployment order, safety, etc.>

## Common Tasks
<frequently used commands>
```

**Size target:** ~2k tokens (1% of budget)

### Step 3: Create Router (docs/_shared/router.md)

```markdown
# Repo Router

## Repository layout map

| Path | Owner | What lives here |
|------|-------|-----------------|
| src/ | Team | Application code |
| docs/ | Team | Documentation |
| .ai/ | AI | AI artifacts |

## Routing triggers

- If asked about **<domain>**:
  - Load: `<paths>`

- If asked about **governance / rules**:
  - Load: `.governance/manifest.json`
  - Load: `.governance/ai/00_INDEX/README.md`

## Disallowed directories
- node_modules/
- dist/
- .terraform/
```

### Step 4: Create Module CLAUDE.md Files (Tier 2)

For each module that needs context:

```markdown
# <Module> CLAUDE.md

## Read Order
1. Root `CLAUDE.md` (required first)
2. This file (module context)

## Module Purpose
<1-2 sentences>

## Key Files
| File | Purpose |
|------|---------|
| main.tf | Primary resources |
| outputs.tf | Exposed outputs |

## Operating Constraints
<module-specific rules>

## Common Commands
```bash
<frequently used commands>
```

## Related Documentation
- `AGENTS.md` - Detailed operations (load if needed)
```

**Size target:** ~2k tokens per module

### Step 5: Create .ai/ Instance Lifecycle

```bash
mkdir -p .ai/{ledger,_scratch,inference,bundles}

# Create ledger
cp .governance/ai/core/templates/golden-image/.ai/ledger/LEDGER.md .ai/ledger/

# Create efficiency tracking (optional)
cp .governance/ai/core/templates/golden-image/.ai/ledger/EFFICIENCY.md .ai/ledger/

# Add to .gitignore
echo ".ai/_scratch/" >> .gitignore
```

### Step 6: Wire Inference Rules (Optional)

If you need repo-local inference rules:

```bash
mkdir -p .ai/inference

# Create local inference
cat > .ai/inference/README.md << 'EOF'
# Repo-Local Inference Rules

These rules override or extend global governance rules.

## Global Rules Reference
See: `.governance/ai/core/inference-rules/`

## Local Overrides
| Rule | Override | Reason |
|------|----------|--------|
EOF
```

---

## Pointer Patterns

### Pattern 1: Forward Reference (Load More Context)

```markdown
## Related Documentation
- For detailed operations, load: `AGENTS.md`
- For troubleshooting, load: `docs/_shared/troubleshooting.md`
```

### Pattern 2: Back Reference (Return to Root)

```markdown
## Read Order
1. Root `CLAUDE.md` (required first)
2. This file
```

### Pattern 3: Cross Reference (Sibling Modules)

```markdown
## Dependencies
This module depends on outputs from:
- `0-base/` - Load if understanding base resources
- `1-network/` - Load if understanding network topology
```

### Pattern 4: Governance Reference

```markdown
## Governance Rules
For deployment safety rules, see:
`.governance/ai/core/conventions/deployment-safety.md`
```

---

## Validation Checklist

After wiring, verify:

| Check | Command | Expected |
|-------|---------|----------|
| Manifest exists | `cat .governance/manifest.json` | Valid JSON |
| Entrypoints exist | `ls` paths from manifest | All files exist |
| Root CLAUDE.md has router pointer | `grep "router" CLAUDE.md` | Reference to router |
| Router has triggers | `grep "If asked" docs/_shared/router.md` | Routing rules exist |
| Module CLAUDE.md files exist | `find . -name "CLAUDE.md"` | One per major module |
| Ledger initialized | `cat .ai/ledger/LEDGER.md` | Template header exists |

---

## Common Wiring Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| No router reference in CLAUDE.md | AI doesn't know how to navigate | Add router to Read Order |
| Missing back-reference in module CLAUDE.md | AI loads module without root context | Add "Root CLAUDE.md required first" |
| Router triggers point to wrong paths | AI loads wrong files | Verify paths exist |
| manifest.json not updated | AI misses new entrypoints | Update entrypoints array |
| Tier 2 files too large | Token budget exceeded | Split into Tier 2 (quick ref) + Tier 3 (detailed) |

---

## Example: IaC Repository Wiring

```
iac-repo/
├── .governance/
│   ├── ai/                    ← Submodule
│   └── manifest.json          ← Discovery
├── CLAUDE.md                  ← Tier 1 (always loaded)
│   └── Pointers to:
│       ├── router.md
│       └── module CLAUDE.md files
├── docs/
│   └── _shared/
│       └── router.md          ← Routing map
│           └── Pointers to:
│               ├── inference rules
│               └── domain docs
├── .ai/
│   ├── ledger/LEDGER.md       ← Operations log
│   └── inference/             ← Local overrides
├── 0-base/
│   └── CLAUDE.md              ← Tier 2 (lazy)
│       └── Pointer to: AGENTS.md (Tier 3)
└── 1-network/
    └── CLAUDE.md              ← Tier 2 (lazy)
```

**Load sequence:**
1. AI reads `manifest.json` → knows what to load
2. AI loads `CLAUDE.md` (Tier 1) → has root context
3. User asks about network → AI loads `1-network/CLAUDE.md` (Tier 2)
4. User needs details → AI loads `1-network/AGENTS.md` (Tier 3)

---

## Integration Points

- **lazy-loading.md**: When to load (triggers, decision tree)
- **three-tier-system.md**: What tiers exist (structure, budgets)
- **this file**: How to wire it together (connections, steps)
- **cost-optimization.md**: Tracking efficiency of loading

---

## Failure Conditions

- ❌ manifest.json missing or invalid
- ❌ Root CLAUDE.md doesn't reference router
- ❌ Router has no routing triggers
- ❌ Module CLAUDE.md files don't back-reference root
- ❌ Tier 2 files exceed token budget (>3k tokens)
