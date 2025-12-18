# Golden Image Template

**Reference implementation for repos adopting the AI Governance Framework**

Copy this template when setting up a new repository with governance.

---

## Directory Structure

```
your-repo/
├── .governance/                  ← WRAPPER (repo-owned)
│   ├── ai/                       ← SUBMODULE (global, read-only)
│   │   └── (governance-ai-framework contents)
│   ├── manifest.json             ← Discovery contract
│   ├── DIRECTORY_CONTRACT.md     ← Points to inference rules
│   └── README.md                 ← Wrapper overview
│
├── .governance-local/            ← REPO CONFIG
│   └── overrides.yaml            ← Repo-specific settings (fill in placeholders)
│
├── .ai/                          ← INSTANCE ARTIFACTS (repo-owned)
│   ├── _scratch/                 ← Ephemeral working files (NEVER COMMIT)
│   ├── bundles/                  ← Executable AI workflows
│   ├── inference/                ← Repo-specific learnings (empty initially)
│   └── ledger/                   ← Audit trail of AI operations
│
├── docs/
│   └── _shared/
│       └── router.md             ← AI routing context map (fill in placeholders)
│
├── .envrc                        ← Auto-initializes submodule
├── .gitmodules                   ← Declares submodule
├── CLAUDE.md                     ← AI quick rules
└── AGENTS.md                     ← Operator guide
```

---

## Key Concepts

### Global vs Instance

| Location | Scope | Ownership | Editable? |
|----------|-------|-----------|-----------|
| `.governance/ai/` | Global (all repos) | Submodule | NO - read-only |
| `.governance/` (wrapper) | This repo | Repo | Yes |
| `.governance-local/` | This repo | Repo | Yes |
| `.ai/` | This repo | Repo | Yes |

### What Lives Where

**Global (in submodule `.governance/ai/`):**
- Core behavioral rules (SYSTEM.md, AGENT_CONTRACT.md)
- Inference rules (lazy-loading, three-tier, directory-contract, file-lifecycle, repo-router)
- Layer-specific conventions (iac, terraform)

**Instance (in `.ai/`):**
- Ledger - audit trail for THIS repo
- Scratch - temporary working files
- Bundles - workflows to run in THIS repo
- Inference - learnings specific to THIS repo

---

## Setup Instructions

### 1. Copy template to new repo
```bash
cp -r core/templates/golden-image/* /path/to/your-repo/
cp -r core/templates/golden-image/.* /path/to/your-repo/
```

### 2. Initialize submodule
```bash
cd /path/to/your-repo
git submodule update --init .governance/ai
```

### 3. Fill in placeholders

Edit these files and replace `<PLACEHOLDERS>`:
- `.governance-local/overrides.yaml` - Set `<REPO_NAME>`, `<TEAM>`
- `docs/_shared/router.md` - Map your repo's directory structure

### 4. Commit
```bash
git add .
git commit -m "feat: Add AI governance framework"
```

---

## Included Bundles

| Bundle | Purpose | Run With |
|--------|---------|----------|
| `ai-file-governance-v1` | Audit file governance compliance | `.ai/bundles/ai-file-governance-v1/RUN.md` |
| `repo-router-v1` | Set up repo routing | `.ai/bundles/repo-router-v1/RUN.md` |

---

## File Classification (A/B/C)

Every file AI creates must be classified:

| Class | Meaning | Examples |
|-------|---------|----------|
| **A** | Repo artifact (ships with repo) | src/, docs/, configs |
| **B** | AI governance artifact | .ai/bundles/, .ai/inference/, ledger |
| **C** | Ephemeral (safe to delete) | .ai/_scratch/* |

**Rule:** Class C files MUST go in `.ai/_scratch/` and are NEVER committed.

---

## See Also

- `../../../core/inference-rules/` - Global inference rules
- `../../../00_INDEX/README.md` - Framework entry point
- `.governance/ai/README.md` - Full framework documentation
