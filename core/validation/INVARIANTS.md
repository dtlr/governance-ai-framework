# Governance Invariants

**Status**: Canonical reference for non-negotiable rules
**Version**: 1.0.0
**Last Updated**: 2025-12-16

---

## What Are Invariants?

Invariants are **rules that must never change**, regardless of:
- Repository type
- User requests
- Model capabilities
- Organizational pressure
- Convenience or expedience

**Any violation is considered a governance failure** and must be corrected immediately.

---

## The 10 Non-Negotiable Invariants

### 1. Micro-Batch Mode (SYSTEM.md:115-161)

**Rule**: AI must operate in micro-batch mode with max 2 file writes per batch.

**Cannot Be Overridden**: Never. Even if:
- Task involves 100 files
- User requests "do it all at once"
- Future models can handle 1000 parallel operations
- CI/CD wants faster execution

**Reason**: Prevents UI freezing, ensures recoverability, maintains user visibility into AI actions.

**Validation**:
```bash
# Check for violations in governance docs
grep -r "complete all at once\|parallel.*write\|unlimited.*batch" .governance/ai/
# Should return: No matches
```

---

### 2. No Auto-Approve (SYSTEM.md:88-93, iac/conventions/deployment-safety.md)

**Rule**: AI must never auto-approve destructive operations or deployments.

**Cannot Be Overridden**: Never. Even if:
- "It's just dev environment"
- "We're in a hurry"
- "I trust the AI"
- CI/CD pipeline requests automation

**Reason**: Infrastructure safety requires human review of all changes before execution.

**Validation**:
```bash
# Check for auto-approve usage
grep -r "auto-approve\|-auto-approve" .governance/ai/
# Should only appear in "NEVER" or "DON'T" contexts
```

---

### 3. SYSTEM.md Precedence (SYSTEM.md:9-27)

**Rule**: If any instruction conflicts with SYSTEM.md, SYSTEM.md wins.

**Cannot Be Overridden**: Never. Even if:
- User explicitly requests override
- Other documentation suggests different approach
- Repo-specific rules contradict SYSTEM.md
- Model has better capabilities

**Reason**: Establishes clear authority hierarchy, prevents erosion of safety rules.

**Validation**:
```bash
# Precedence rule must exist
grep -q "If any instruction conflicts with this file, this file wins" .governance/ai/core/rules/SYSTEM.md
echo $? # Should be 0 (found)
```

---

### 4. Freeze-Proof Enforcement (SYSTEM.md:19-27)

**Rule**: AI must never attempt to complete an entire multi-step plan in one response.

**Cannot Be Overridden**: Never. Even if:
- Model technically capable
- Task could be done faster
- User requests bulk completion
- Other AI tools allow it

**Reason**: Prevents "helpful but destructive" behavior, maintains control, ensures UI responsiveness.

**Validation**:
```bash
# Freeze-proof rule must exist
grep -q "must never attempt to complete an entire multi-step plan in one response" .governance/ai/core/rules/SYSTEM.md
echo $? # Should be 0 (found)
```

---

### 5. Tier 1 Token Budget (00_INDEX/README.md:48, three-tier-system.md)

**Rule**: Tier 1 context must remain under ~15k tokens (typical).

**Cannot Be Overridden**: Soft limit (advisory), but entrypoint count is hard limit.

**Hard Limit**: Max 7 entrypoints in manifest.json

**Reason**: Ensures fast session startup, prevents context bloat, maintains lazy loading benefits.

**Validation**:
```bash
# Check entrypoint count
jq '.entrypoints | length' .governance/manifest.json
# Should be ≤7
```

---

### 6. No Submodule In-Place Modifications

**Rule**: Governance submodule (.governance/ai/) must never be modified directly in consuming repos.

**Cannot Be Overridden**: Never. Even if:
- "Just a small fix"
- "Only for this repo"
- "Emergency change needed"
- Submodule update process is slow

**Reason**: Maintains single source of truth, prevents fragmentation, ensures consistent behavior.

**Validation**:
```bash
# Check for local commits to submodule
cd .governance/ai && git log --oneline origin/main..HEAD
# Should be empty (no local commits)
```

---

### 7. Mandatory State Cache Updates (iac/conventions/deployment-safety.md)

**Rule**: After every terraform/tofu apply, STATE_CACHE.md must be updated via update_state_cache.sh.

**Cannot Be Overridden**: Never. Even if:
- "Just a small change"
- "No new resources added"
- "Will do it later"
- Automated pipeline

**Reason**: Prevents documentation drift, ensures AI has accurate context, maintains Tier 3 reliability.

**Validation**:
```bash
# STATE_CACHE.md should be newer than or equal to .tf file commits
last_cache=$(stat -c %Y STATE_CACHE.md)
last_tf=$(git log -1 --format=%ct -- "*.tf")
[ $last_cache -ge $last_tf ] && echo "✓ Cache current" || echo "✗ Cache stale"
```

---

### 8. No Directory Scanning (manifest.json, lazy-loading.md)

**Rule**: Manifest must use explicit file paths, never wildcards or directory scanning.

**Cannot Be Overridden**: Never. Even if:
- "Makes things more flexible"
- "Easier to maintain"
- "Other tools do it"
- Want auto-discovery

**Reason**: Deterministic loading, prevents unexpected token explosions, maintains predictable behavior.

**Validation**:
```bash
# Check manifest for wildcards
jq -r '.entrypoints[]' .governance/manifest.json | grep -E '\*|\.\.|\.$'
# Should return: No matches
```

---

### 9. Saved Plans Only (iac/conventions/deployment-safety.md)

**Rule**: All terraform/tofu applies must use saved plans (tofu plan -out=tofu.plan, then tofu apply tofu.plan).

**Cannot Be Overridden**: Never. Even if:
- "Plan hasn't changed"
- "Just refreshing state"
- "Emergency fix"
- Automated deployment

**Reason**: Ensures user reviews exactly what will be applied, prevents race conditions, maintains audit trail.

**Validation**:
```bash
# Check for direct apply without saved plan
git log --all -p | grep -E "tofu apply(?! [a-zA-Z0-9._-]+\.tfplan)"
# Should not find recent instances
```

---

### 10. Transparency Over Assumptions (SYSTEM.md:33-45)

**Rule**: AI must always state what it's about to do before doing it, never silently guess.

**Cannot Be Overridden**: Never. Even if:
- "I know what user means"
- "Obvious from context"
- "Faster without explaining"
- User seems impatient

**Reason**: Builds trust, enables debugging, prevents errors from misunderstanding, maintains user control.

**Validation**:
- Qualitative: Review AI sessions for unexplained actions
- Enforcement: AI self-policing via SYSTEM.md contract

---

## Invariant Violation Response Protocol

If an invariant is violated:

### 1. Immediate Actions

```
STOP → Identify which invariant was violated
     → Rollback if possible
     → Document the violation
     → Alert team
```

### 2. Root Cause Analysis

- **Was it a bug?** → Fix in code/docs
- **Was it a user request?** → Educate user on why invariant exists
- **Was it organizational pressure?** → Escalate to leadership
- **Was it AI misunderstanding?** → Improve rule clarity

### 3. Prevention

- Update documentation to make invariant more explicit
- Add validation check (CI/CD if possible)
- Add to CI_CHECKLIST.md for v1.1.0 enforcement
- Review other repos for same violation

### 4. Communication

- Notify all teams using governance framework
- Update CHANGELOG.md with violation details
- If framework bug: Release patch version

---

## Human Override Boundaries

### Humans MAY Override

These are **recommendations** that can be adjusted per repo:

- Token budget targets (15k/25k/60k are illustrative)
- Specific tools used (terraform vs tofu, npm vs pnpm)
- Deployment procedures (as long as safety rules met)
- Commit message formats (as long as conventional)
- Documentation structure (as long as lazy loading preserved)
- Repo-specific rules in `.governance-local/overrides.yaml`

### Humans MAY NOT Override

These are **invariants** that cannot be changed:

- Micro-batch mode (max 2 files per batch)
- No auto-approve for destructive operations
- SYSTEM.md precedence (it always wins)
- Freeze-proof enforcement (no bulk completion)
- Saved plans for all applies
- State cache updates after applies
- No submodule in-place modifications
- No directory scanning in manifest
- Transparency requirement (explain before acting)
- Max entrypoint count (7 in manifest.json)

**Why This Distinction Matters**:
- Invariants ensure safety and reliability
- Overridable items allow customization
- Clear boundaries prevent gradual erosion

---

## Checking Invariant Compliance

### Quick Check (30 seconds)

```bash
# Run from repo root
cd /path/to/repo

# 1. Check precedence rule exists
grep -q "this file wins" .governance/ai/core/rules/SYSTEM.md && echo "✓ Precedence" || echo "✗ Missing"

# 2. Check freeze-proof rule exists
grep -q "must never attempt to complete an entire multi-step plan" .governance/ai/core/rules/SYSTEM.md && echo "✓ Freeze-proof" || echo "✗ Missing"

# 3. Check entrypoint count
count=$(jq '.entrypoints | length' .governance/manifest.json)
[ $count -le 7 ] && echo "✓ Entrypoints: $count/7" || echo "✗ Too many: $count"

# 4. Check for submodule modifications
cd .governance/ai && git log --oneline origin/main..HEAD | wc -l
cd ../..
# Should be 0 (no local commits)

# 5. Check STATE_CACHE.md freshness
[ -f STATE_CACHE.md ] && echo "✓ State cache exists" || echo "⚠ No state cache"
```

### Full Audit (5 minutes)

```bash
# Run all checks from CI_CHECKLIST.md
python scripts/governance/validate_invariants.py

# Expected output:
# ✓ Precedence rule exists
# ✓ Freeze-proof rule exists
# ✓ Entrypoint count: 5/7
# ✓ No submodule modifications
# ✓ No auto-approve rules found
# ✓ No wildcard loading found
# ✓ All entrypoints exist
# ✓ No broken references
# ✅ All 8 checks passed
```

---

## Enforcement Levels

### Level 1: Documentation (Current - v1.0.0)

- Invariants documented in this file
- Referenced in SYSTEM.md, ADOPTION_GUIDE.md, etc.
- AI self-policing via SYSTEM.md contract
- Human review via monthly audits

### Level 2: CI Validation (Planned - v1.1.0)

- Automated checks on every PR
- Blocks merge if invariants violated
- Actionable error messages
- Implementation: CI_CHECKLIST.md → GitHub Actions

### Level 3: Runtime Enforcement (Future - v2.0.0)

- AI tool wrappers that prevent violations
- Pre-commit hooks block bad commits
- IDE plugins show invariant status
- Real-time governance dashboard

---

## Why These Specific 10 Invariants?

### Chosen Based On:

1. **Safety Impact**: Violations could cause production incidents
2. **Trust Impact**: Violations erode user confidence in AI
3. **Measurability**: Can be verified programmatically
4. **Universality**: Apply to all repo types
5. **Non-Negotiability**: No valid reason to disable

### What's NOT an Invariant:

- Specific token counts (these vary by model/tokenizer)
- Specific tools (terraform vs tofu, npm vs pnpm)
- File naming conventions (CLAUDE.md vs AI.md)
- Commit message format details (as long as conventional)
- Documentation structure (as long as principles met)

These are **conventions** that can be customized per repo/org.

---

## Governance Versioning

When invariants change:

- **Patch (1.0.X)**: Clarification, no behavior change
- **Minor (1.X.0)**: New invariant added, old ones unchanged
- **Major (X.0.0)**: Existing invariant removed or weakened

**Expectation**: Invariants should be **very stable**. Major version bumps should be rare (years, not months).

---

## Summary: The 10 Invariants

1. ✓ Micro-batch mode (max 2 files)
2. ✓ No auto-approve
3. ✓ SYSTEM.md precedence
4. ✓ Freeze-proof enforcement
5. ✓ Tier 1 token budget (~15k, max 7 entrypoints)
6. ✓ No submodule in-place modifications
7. ✓ Mandatory state cache updates
8. ✓ No directory scanning
9. ✓ Saved plans only
10. ✓ Transparency over assumptions

**If you violate one**: Stop, rollback, document, fix, prevent.

**If you find a violation**: Report immediately to framework maintainers.

**If you want to change one**: Propose as Major version (expect high bar for approval).

---

**Related Documentation**:
- `.governance/ai/core/rules/SYSTEM.md` - Canonical source for rules 1-4, 10
- `.governance/ai/iac/conventions/deployment-safety.md` - Canonical source for rules 2, 7, 9
- `.governance/ai/00_INDEX/README.md` - Canonical source for rule 5
- `.governance/manifest.json` - Enforcement of rules 5, 8
- `.governance/ai/core/validation/CI_CHECKLIST.md` - Programmatic checks (v1.1.0)

---

**Version**: 1.0.0
**Status**: Canonical
**Maintained By**: Framework maintainers
**Review Cadence**: Annually (or when governance failure occurs)
