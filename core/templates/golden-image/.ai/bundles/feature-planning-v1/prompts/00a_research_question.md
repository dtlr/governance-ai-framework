# Prompt 00a: Research Question (Standalone)

## Context
You are a Cloud Architect researching a question that may or may not relate to a specific codebase.

## Input
Read: `.ai/_scratch/user-request.md`

This may be:
- A general architecture question ("Best way to manage golden Linux images on Azure")
- A technology comparison ("Redis vs Memcached for session caching")
- A best practices query ("How should I structure Terraform for multi-region?")
- A repo-specific question (will be handled differently)

## Task
Analyze the question and produce a structured research plan.

## Instructions

### 1. Classify the Question

| Type | Description | Example |
|------|-------------|---------|
| ARCHITECTURE | System design, patterns | "How to design multi-region failover" |
| COMPARISON | Evaluating options | "Redis vs Memcached" |
| BEST_PRACTICE | How to do X properly | "Terraform module structure" |
| IMPLEMENTATION | Build specific thing | "Add Redis to our Azure setup" |
| TROUBLESHOOTING | Fix/debug issue | "Why is my AKS pod failing" |

### 2. Identify Research Sources

Based on question type, determine which sources to consult:

**For Azure questions:**
- Azure Well-Architected Framework
- Azure Architecture Center
- Microsoft Learn documentation
- Azure pricing calculator

**For Terraform/IaC:**
- OpenTofu/Terraform docs
- Provider documentation (azurerm, aws, etc.)
- Module registry best practices

**For Kubernetes:**
- Kubernetes.io documentation
- AKS/EKS/GKE specific docs
- CNCF project docs

**For General:**
- Cloud provider comparisons
- Industry benchmarks
- Community best practices (Reddit, HN, StackOverflow patterns)

### 3. Define Research Questions

Break the main question into sub-questions:

```markdown
## Main Question
[User's original question]

## Sub-Questions to Research
1. [Technical question 1]
2. [Technical question 2]
3. [Cost/pricing question]
4. [Security consideration]
5. [Operational consideration]
```

### 4. Output to `.ai/_scratch/research-plan.md`:

```markdown
# Research Plan

## Question Analysis

| Field | Value |
|-------|-------|
| Original Question | [user input] |
| Type | [ARCHITECTURE/COMPARISON/BEST_PRACTICE/IMPLEMENTATION/TROUBLESHOOTING] |
| Repo Context Required | [YES/NO] |
| Estimated Research Time | [X minutes] |

## Research Sources

### Primary Sources (Official)
- [ ] [Source 1 - URL]
- [ ] [Source 2 - URL]

### Secondary Sources (Community)
- [ ] [Source 1]

## Sub-Questions

1. **[Sub-question 1]**
   - Sources: [which docs to check]
   - Expected output: [what we need to find]

2. **[Sub-question 2]**
   - Sources: [which docs]
   - Expected output: [what to find]

## Output Format

The research will produce:
- [ ] Options comparison table
- [ ] Pros/cons for each option
- [ ] Recommendation with reasoning
- [ ] Cost estimates (if applicable)
- [ ] Security considerations
- [ ] Implementation complexity rating

## Repo Relevance

[If applicable: How this relates to the current repo]
[If not applicable: "Standalone research - no repo changes needed"]
```

## Completion
Say "Research plan created. Ready for deep research."
