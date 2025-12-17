# CI Validation Checklist

**Purpose**: Programmatic enforcement of governance invariants to prevent drift

**Status**: Specification (implementation planned for v1.1.0)

---

## Critical Invariants to Enforce

### 1. Micro-Batch Guarantees

**Rule**: System must not allow instructions that violate micro-batch mode

**Checks**:
```yaml
- name: Check for auto-batch-complete rules
  pattern: '(complete.*entire|all.*in.*one|parallel.*write|batch.*unlimited)'
  files: ['**/*.md']
  fail_if_found: true
  reason: "Would violate micro-batch mode (max 2 files)"

- name: Check for >2 files per batch allowance
  pattern: 'max.*[3-9].*files|write.*[3-9].*files'
  files: ['core/rules/*.md']
  fail_if_found: true
  reason: "Micro-batch mode is max 2 files per batch"
```

---

### 2. No Wildcard Loading

**Rule**: Manifest must not contain directory scanning or wildcard loads

**Checks**:
```yaml
- name: No wildcard entrypoints
  files: ['**/manifest.json']
  schema_validation:
    entrypoints:
      type: array
      items:
        pattern: '^[a-zA-Z0-9/_.-]+\.md$'  # Explicit file paths only
        no_wildcards: true

- name: No find/scan instructions
  pattern: '(find.*-name|scan.*directory|load.*all.*\.md|glob.*pattern)'
  files: ['00_INDEX/*.md', 'core/rules/*.md']
  fail_if_found: true
  reason: "Would introduce directory scanning, violating deterministic loading"
```

---

### 3. Tier 1 Token Creep Prevention

**Rule**: Root tier must remain lightweight (entrypoints bounded)

**Checks**:
```yaml
- name: Max entrypoints count
  file: .governance/manifest.json
  max_entrypoints: 7
  current_count: 5
  reason: "Tier 1 must stay lightweight. Each entrypoint adds ~3-5k tokens."

- name: Entrypoint file size limits
  files: ['00_INDEX/*.md', 'core/rules/*.md']
  max_lines: 600
  reason: "Prevent individual file bloat that explodes Tier 1 token count"
```

---

### 4. No Auto-Approve Rules

**Rule**: System must not allow instructions that bypass safety checks

**Checks**:
```yaml
- name: Check for auto-approve allowances
  pattern: '(may.*auto-approve|allow.*-auto-approve|skip.*validation.*if)'
  files: ['**/*.md']
  fail_if_found: true
  reason: "Would bypass deployment safety protocol"

- name: Check for validation bypass
  pattern: '(optional.*validation|skip.*validate_env|bypass.*safety)'
  files: ['iac/conventions/*.md', 'terraform/conventions/*.md']
  fail_if_found: true
  reason: "Validation is mandatory for infrastructure operations"
```

---

### 5. Precedence Rule Integrity

**Rule**: SYSTEM.md precedence must not be contradicted

**Checks**:
```yaml
- name: Precedence rule exists
  file: .governance/ai/core/rules/SYSTEM.md
  must_contain: "If any instruction conflicts with this file, this file wins"
  reason: "Precedence rule establishes authority hierarchy"

- name: No override allowances
  pattern: '(unless.*required|may.*override.*SYSTEM|can.*ignore.*if)'
  files: ['**/*.md']
  exclude: ['SYSTEM.md']
  fail_if_found: true
  reason: "No file should allow overriding SYSTEM.md"
```

---

### 6. Freeze-Proof Enforcement

**Rule**: Multi-step completion constraint must remain enforced

**Checks**:
```yaml
- name: Freeze-proof rule exists
  file: .governance/ai/core/rules/SYSTEM.md
  must_contain: "must never attempt to complete an entire multi-step plan in one response"
  reason: "Prevents future models from bypassing micro-batch discipline"

- name: No bulk completion allowances
  pattern: '(complete.*all.*steps|finish.*everything|skip.*batching)'
  files: ['**/*.md']
  fail_if_found: true
  reason: "Would violate freeze-proof enforcement"
```

---

### 7. Layered Architecture Integrity

**Rule**: No layer should duplicate or contradict another layer

**Checks**:
```yaml
- name: No core rules in iac layer
  pattern: '(micro-batch|lazy.loading|three.tier|git.workflow)'
  files: ['iac/**/*.md']
  fail_if_found: true
  reason: "Core rules belong in core/, not iac/"

- name: No iac rules in terraform layer
  pattern: '(deployment.safety|state.management|validate_env)'
  files: ['terraform/**/*.md']
  fail_if_found: true
  reason: "IaC rules belong in iac/, not terraform/"
```

---

### 8. Manifest Validity

**Rule**: All manifest entrypoints must exist and be valid

**Checks**:
```yaml
- name: Entrypoints exist
  file: .governance/manifest.json
  validate_paths:
    base: .governance/ai
    entrypoints: all
    must_exist: true

- name: Schema reference valid
  file: .governance/manifest.json
  field: $schema
  must_match: 'ai/core/schemas/manifest\.schema\.json'
  reason: "Schema path must be relative to governance root"
```

---

### 9. No Broken Internal References

**Rule**: All cross-references between governance files must be valid

**Checks**:
```yaml
- name: Internal markdown links
  files: ['.governance/**/*.md']
  validate_links:
    internal_only: true
    base: .governance/ai
    must_exist: true

- name: No references to old structure
  pattern: '\.governance/(core|iac|terraform)/'
  files: ['.governance/**/*.md']
  fail_if_found: true
  reason: "Old structure was migrated to .governance/ai/"
```

---

### 10. Token Number Advisories

**Rule**: Token counts should be marked as illustrative, not contractual

**Checks**:
```yaml
- name: Token counts are advisory
  files: ['**/*.md']
  when_contains: '(\d+k tokens|~\d+k|[0-9]+k token)'
  must_have_nearby:
    - 'approximate'
    - 'typical'
    - 'example'
    - 'illustrative'
  reason: "Token counts are examples, not guarantees"
```

---

## CI Workflow Structure (Planned)

```yaml
name: Governance Validation

on:
  pull_request:
    paths:
      - '.governance/**'
  push:
    branches: [main, restructure]
    paths:
      - '.governance/**'

jobs:
  validate-governance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Validate Manifest
        run: |
          # Check manifest.json structure
          python scripts/governance/validate_manifest.py

      - name: Check Invariants
        run: |
          # Run all checks from this checklist
          python scripts/governance/validate_invariants.py

      - name: Verify Entrypoints
        run: |
          # Ensure all manifest entrypoints exist
          bash scripts/governance/verify_entrypoints.sh

      - name: Check for Drift
        run: |
          # Detect violations of critical rules
          python scripts/governance/check_drift.py

      - name: Report
        if: failure()
        run: |
          echo "❌ Governance validation failed"
          echo "See checks above for specific violations"
          exit 1
```

---

## Implementation Priority (v1.1.0)

### High Priority (Must Have)
1. Micro-batch guarantees check
2. No auto-approve rules check
3. Precedence rule integrity check
4. Freeze-proof enforcement check
5. Manifest validity check

### Medium Priority (Should Have)
6. Tier 1 token creep prevention
7. No wildcard loading check
8. Layered architecture integrity
9. No broken internal references

### Low Priority (Nice to Have)
10. Token number advisories check

---

## Validation Scripts (To Be Implemented)

### `scripts/governance/validate_manifest.py`
```python
#!/usr/bin/env python3
"""Validate governance manifest structure and entrypoints."""

import json
import sys
from pathlib import Path

def validate_manifest(manifest_path):
    """Validate manifest.json against schema and rules."""
    with open(manifest_path) as f:
        manifest = json.load(f)

    # Check required fields
    required = ['version', 'governance_root', 'entrypoints']
    for field in required:
        if field not in manifest:
            print(f"❌ Missing required field: {field}")
            return False

    # Check entrypoints exist
    gov_root = Path(manifest['governance_root'])
    for entrypoint in manifest['entrypoints']:
        path = gov_root / entrypoint
        if not path.exists():
            print(f"❌ Entrypoint not found: {entrypoint}")
            return False

    # Check max entrypoints (token creep prevention)
    if len(manifest['entrypoints']) > 7:
        print(f"❌ Too many entrypoints: {len(manifest['entrypoints'])} (max 7)")
        return False

    print("✅ Manifest validation passed")
    return True

if __name__ == '__main__':
    success = validate_manifest('.governance/manifest.json')
    sys.exit(0 if success else 1)
```

### `scripts/governance/validate_invariants.py`
```python
#!/usr/bin/env python3
"""Validate governance invariants from CI_CHECKLIST.md."""

import re
import sys
from pathlib import Path

CHECKS = [
    {
        'name': 'No auto-approve rules',
        'pattern': r'(may.*auto-approve|allow.*-auto-approve)',
        'files': ['.governance/**/*.md'],
        'reason': 'Would bypass deployment safety'
    },
    {
        'name': 'Precedence rule exists',
        'file': '.governance/ai/core/rules/SYSTEM.md',
        'must_contain': 'If any instruction conflicts with this file, this file wins',
        'reason': 'Establishes authority hierarchy'
    },
    {
        'name': 'Freeze-proof rule exists',
        'file': '.governance/ai/core/rules/SYSTEM.md',
        'must_contain': 'must never attempt to complete an entire multi-step plan in one response',
        'reason': 'Prevents bypassing micro-batch discipline'
    },
]

def run_checks():
    """Run all invariant checks."""
    passed = 0
    failed = 0

    for check in CHECKS:
        # Implementation of check logic
        # (Pattern matching, file existence, etc.)
        pass

    if failed > 0:
        print(f"❌ {failed} checks failed")
        return False

    print(f"✅ All {passed} checks passed")
    return True

if __name__ == '__main__':
    success = run_checks()
    sys.exit(0 if success else 1)
```

---

## Testing the Checks

Before implementing CI:

```bash
# Manual validation
cd .governance/ai

# Check 1: No auto-approve rules
grep -r "auto-approve" . && echo "❌ Found auto-approve reference"

# Check 2: Precedence rule exists
grep -q "If any instruction conflicts" core/rules/SYSTEM.md && echo "✅ Precedence rule present"

# Check 3: Freeze-proof rule exists
grep -q "must never attempt to complete" core/rules/SYSTEM.md && echo "✅ Freeze-proof rule present"

# Check 4: Max entrypoints
count=$(jq '.entrypoints | length' ../manifest.json)
[ $count -le 7 ] && echo "✅ Entrypoint count OK ($count/7)"

# Check 5: All entrypoints exist
jq -r '.entrypoints[]' ../manifest.json | while read file; do
  [ -f "$file" ] && echo "✅ $file" || echo "❌ $file missing"
done
```

---

## Future Enhancements (v1.2.0+)

### Drift Detection
- Compare generated docs with actual state
- Detect when STATE_CACHE.md falls out of sync
- Auto-generate PR to update stale documentation

### Token Usage Analytics
- Track actual token usage in real sessions
- Identify tier escalation patterns
- Optimize routing logic based on real data

### Multi-Repo Testing
- Run governance validation across all repos
- Detect version drift (repo X on v1.0.0, repo Y on v1.2.0)
- Auto-generate compatibility reports

---

## Notes

- This is a **specification**, not implementation
- Actual checks should be implemented in v1.1.0
- Checks should be fast (<30 seconds total)
- Failing checks should provide actionable error messages
- Warnings should be distinct from errors

**The goal**: Make it **hard to accidentally break** governance guarantees, even as the system evolves.
