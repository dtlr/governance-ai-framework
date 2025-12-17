# PDR: Golden Image Governance Wrapper + AI Artifact Lifecycle

## Problem
Repos drift in governance adoption and AI-generated artifacts create clutter without a consistent lifecycle.

## Goals
- Standardize governance wrapper (`.governance/manifest.json`, `.governance-local/overrides.yaml`)
- Standardize AI artifact lifecycle (`.ai/ledger`, `.ai/_scratch`, bundles)
- Enable lazy loading via manifest tiering
- Make adoption repeatable across many repos

## Success Criteria
- A new repo can adopt governance via submodule and wrappers with minimal effort
- AI runs do not create untracked clutter
- Ledger provides provenance and review clarity
