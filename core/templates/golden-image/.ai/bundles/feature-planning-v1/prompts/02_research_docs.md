# Prompt 02: Research Official Documentation

## Context
Codebase research complete. Now validate against official documentation.

## Input
Read:
- `.ai/_scratch/research/codebase.md`
- `.ai/bundles/DOCUMENTATION_STANDARDS.md` (if exists)
- `.governance/ai/core/inference-rules/` (for patterns)

## Task
Research official documentation to:
1. Validate the proposed approach
2. Find best practices
3. Identify gotchas and warnings
4. Discover better alternatives

## Instructions

1. **Load documentation standards**:
   If `.ai/bundles/DOCUMENTATION_STANDARDS.md` exists, use it to find relevant official docs.
   
2. **For each technology involved**, research:
   
   **Terraform/OpenTofu**:
   - Provider documentation for resources used
   - Module structure best practices
   - State management implications
   
   **Cloud Providers** (Azure, DO, Cloudflare):
   - Service-specific best practices
   - Security recommendations
   - Pricing/quota implications
   - Regional availability
   
   **Kubernetes/ArgoCD** (if applicable):
   - Deployment patterns
   - Resource limits
   - Security contexts

3. **Document findings by category**:

   | Category | Finding | Source | Relevance |
   |----------|---------|--------|-----------|
   | Best Practice | [what] | [official doc URL] | [how it applies] |
   | Warning | [what to avoid] | [source] | [why it matters] |
   | Alternative | [different approach] | [source] | [tradeoffs] |

4. **Output to `.ai/_scratch/research/docs.md`**:

```markdown
# Documentation Research

## Official Sources Consulted
| Source | URL | Topics |
|--------|-----|--------|
| [Provider Docs] | [URL] | [what was researched] |

## Best Practices Found

### [Topic 1]
**Source**: [URL]
**Recommendation**: [what the docs say]
**Application**: [how it applies to this request]

### [Topic 2]
...

## Warnings and Gotchas

### ⚠️ [Warning Title]
**Source**: [URL]
**Issue**: [what could go wrong]
**Mitigation**: [how to avoid it]

## Alternative Approaches Discovered

### Option A: [Name]
**Source**: [URL]
**Pros**: [advantages]
**Cons**: [disadvantages]
**Verdict**: [recommended/not recommended]

### Option B: [Name]
...

## Security Considerations
- [Security item 1]
- [Security item 2]

## Cost/Performance Implications
- [Cost item 1]
- [Performance item 1]

## Version/Compatibility Notes
- [Provider version requirements]
- [API version considerations]

## Outstanding Questions
- [Questions that docs didn't answer]
```

## Completion
Say "Documentation research complete. Ready for validation."
