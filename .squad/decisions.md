# Squad Decisions

## Active Decisions

### 1. Quickstart Scope (Atlas)

**Date:** 2024-04-22  
**Author:** Atlas  
**Status:** Active

The quickstart (`examples/quickstart/`) is a smoke test, not a production blueprint.

**Included:**
- AGC provisioning (Terraform module call)
- Gateway + HTTPRoute manifests (Gateway API v1)
- Single HTTP listener (port 80, no TLS)
- Single backend service (nginx-unprivileged)
- Kustomize structure for `kubectl apply -k`

**Excluded:**
- HTTPS/TLS (out of scope for smoke test)
- NetworkPolicy (Sentinel's domain)
- ALZ Corp wiring (documented separately in docs/runbook/)
- Workload identity (Iris's domain, not needed for smoke test)
- Multiple routes, path rewrites, header manipulation (covered in catalog/samples)

**Rationale:** Quickstart must succeed in under 10 minutes with zero prerequisites beyond Azure subscription + AKS cluster. Users wanting production setup should read `docs/runbook/`.

### 2. Migration Plan Schema v1: Location and Version Policy (Forge)

**Date:** 2026-04-22  
**Author:** Forge  
**Status:** Active

**File structure:**
- **Entry point:** `schema/migration-plan.v1.json` (compatibility entry point, stable URL for consumers)
- **Canonical schema:** `schemas/migration-plan/v1/schema.json` (JSON Schema draft 2020-12)
- **Examples:** `schemas/migration-plan/v1/examples/*.{json,yaml}` (both formats for contract testing)

**Version policy:**
- v1 is the initial stable release
- Breaking changes increment version (v1 → v2 → v3)
- Entry point remains at `schema/migration-plan.v1.json` for stable consumers
- New versions create versioned directories: `schemas/migration-plan/v2/schema.json`
- Non-breaking additions do not increment version

**ADR-001 alignment:** Per ADR-001, this schema is the orchestration contract. This repo coordinates upstream translation tools (ingress2gateway) and provides ALZ Corp IaC workflows. Schema structure supports all 10 migration phases and action types (manual, kubectl, helm, terraform, bicep, powershell).

### 3. PowerShell Migration Scripts Philosophy (Forge)

**Date:** 2026-05-12  
**Author:** Forge  
**Status:** Active

PowerShell migration scripts follow a **read-only-first, human-driven cutover** philosophy.

**Read-only first:** All scripts default to dry-run or preview mode.
- `Convert-IngressToGateway`: `-WhatIf` defaults to `$true`
- `Invoke-TrafficCutover`: `-DryRun` defaults to `$true`
- `Get-MigrationAssessment`: Read-only by design

**Human-driven traffic cutover:** Automated traffic cutover is intentionally excluded. Traffic shifts are high-risk; DNS propagation delays, routing loops, and partial failures require human judgment.

**Script boundaries:** Each script has one responsibility:
- `Convert-IngressToGateway`: Translate Ingress YAML to HTTPRoute YAML (no cluster changes)
- `Get-MigrationAssessment`: Read cluster state, report inventory (no changes)
- `Invoke-TrafficCutover`: Compare routes, generate Markdown checklist (no changes)

**Intentionally human-only actions:** DNS updates, traffic validation, monitoring, and decommissioning are human gates because they require context and environment-specific judgment.

### 4. Required Status Checks for Main Branch (Lead)

**Date:** 2026-05-12  
**Author:** Lead  
**Status:** Active

**Canonical list of required status checks for `main` branch:**
- `scan` (gitleaks)
- `analyze (actions)` (CodeQL with matrix)
- `review` (dependency review action)
- `terraform` (validate.yml job, unprefixed)
- `bicep` (validate.yml job, unprefixed)
- `manifests` (validate.yml job, unprefixed)
- `Validate AGC Module Parity` (iac-parity.yml workflow name)

**Rationale:** These checks gate merge to main:
- Security: gitleaks, CodeQL, dependency review
- IaC quality: terraform/bicep validate
- Manifest quality: kubeconform + helm lint
- Parity enforcement: Terraform-Bicep output equivalence

**Implementation:** Workflow `.github/workflows/branch-protection.yml` applies these via GitHub API `updateBranchProtection`. Merged as PR #45.

**Note:** GitHub status check names are case-sensitive and based on job IDs (without explicit `name:` keys) or workflow names, not inferred from workflow `name:` field. Matrix jobs append suffixes to the display name.

### 5. Officialness Disclaimer for Customer-Facing Docs (Sage)

**Date:** 2026-04-22  
**Author:** Sage  
**Status:** Active

All customer-facing documentation requires a disclaimer immediately after the main heading:

> "*Not an official Microsoft product. Community migration toolkit. See LICENSE.*"

**Implementation:**
- Canonical disclaimer in `docs/_disclaimer.md`
- Required for all ADRs and new customer-facing documentation
- Enforced in CONTRIBUTING.md

**Rationale:** Clarifies project status and liability. Community ownership is explicit.

### 6. Presentation Deck Location and Maintenance (Sage)

**Date:** 2026-04-22  
**Author:** Sage  
**Status:** Active

The AKS Automatic ingress-nginx → AGC migration presentation deck is a self-contained HTML file at `presentation/index.html` using reveal.js from CDN. No build step required.

**Structure:** 5 sections, 30 slides:
1. The clock is ticking (5 slides): Retirement timelines, why now, migration target
2. What changes (7 slides): Ingress vs Gateway API mental model, YAML comparison, annotation gaps
3. Where AGC lives in ALZ Corp (7 slides): Hub-spoke, Azure Firewall egress, AGC placement, Workload Identity
4. The runbook (7 slides): 10-phase timeline and key phases
5. Try it (4 slides): Quickstart, contribute, closing

**Update triggers:** Update when retirement dates change, preview status changes, runbook phase count changes, annotation gaps change, or ALZ Corp assumptions change. Do NOT update for minor wording, example code, or typo fixes.

**Maintenance:** Edit `presentation/index.html` directly, test in browser, verify citations load, commit and push.

### 7. 10-Phase Runbook Structure (Sage)

**Date:** 2026-04-22  
**Author:** Sage  
**Status:** Active

The migration runbook is structured as 10 sequential phase files (00-09) under `docs/runbook/`, each representing an atomic migration step.

**Phase boundaries:**
- **00:** AGC Availability Prerequisites (read-only, no infra changes)
- **01:** Assess Current Ingress (read-only, baseline capture)
- **02:** Provision AGC (low rollback complexity)
- **03:** Deploy AGC Controller (low rollback complexity)
- **04:** Translate Manifests (low rollback complexity)
- **05:** Coexistence Testing (low rollback complexity)
- **06:** Production Cutover (medium rollback complexity, 2-5 min window)
- **07:** Post-Cutover Validation (medium rollback complexity)
- **08:** Decommission ingress-nginx (high rollback complexity, 30-60 min)
- **09:** Rollback Procedures (reference only)

**Design principles:**
1. Atomic rollback units: Each phase can roll back independently
2. Validation gates: Checkbox criteria before proceeding
3. Dry-run first: All commands default to plan/what-if before live execution
4. Citation policy: Every claim links to MS Learn or GitHub with access date
5. ALZ Corp defaults: Private AKS clusters, hub-spoke, central firewall, Workload Identity
6. Template consistency: All phases follow the same 7-section structure (Goal, Prerequisites, Steps, Validation, Rollback, References)

### 8. PR Triage Decision: 2026-05-12 (Lead)

**Date:** 2026-05-12  
**Author:** Lead  
**Status:** Completed

Triaged 10 draft @copilot PRs. Result: 8 approved ready for merge, 2 left in draft with REQUEST_CHANGES comments.

**Approved for merge:** #23, #24, #25, #26, #27, #28, #35, #36

**REQUEST_CHANGES:** 
- #29 (branch-protection): Check name case mismatch (`Analyze` vs `analyze`). Later fixed and merged as PR #45.
- #37 (migration schema): Missing canonical schema file. Later added and merged as PR #46.

**Key learning:** @copilot output quality is generally strong. Case-sensitivity pitfall occurs when GitHub Actions uses matrix suffixes; recommend explicit guidance on exact check names as displayed in Actions UI.

### 9. Project voice profile adopted as standard (Coordinator)

**Date:** 2026-05-12  
**Author:** martinopedal (via Squad coordinator)  
**Status:** Active

Project prose now follows the voice profile at `.squad/skills/voice-profile/SKILL.md`. Profile is anonymized from maintainer's `C:\git\news-fetcher\src\drafts\voice_profile.md` (2026-05 revision) and global `~/.copilot/skills/writer/SKILL.md`.

**Applies to:** All prose in the repository. Docs, ADRs, runbook, READMEs, presentation copy, PR descriptions, commit messages.

**Core rules:**
- No em dashes or en dashes. Use commas, periods, or "and" instead.
- Emojis restricted to `✓` (checkmark) and `✗` (cross) as status markers only.
- Banned phrases: "leveraging", "seamless", "unlock", "journey", "robust", "comprehensive", "cutting-edge", "deep dive", "furthermore", "moreover", "additionally", "at the end of the day", "elevate", "empower", "accelerate", "streamline", "optimize", "enterprise-grade", "production-ready", "future-proof", "AI-powered", "digital transformation", and 20+ others.

**Anti-AI structural rules:** No question-then-answer rhythm, no forced analogies, no bold-heading-list filler, no tricolon openers, no moral-of-story endings, no false-contrast frames.

**Quality gate:** Before any prose is merged, verify (1) opening sentence stops scroll, (2) at least one specific technical detail (version, default, flag, subnet size), (3) concrete CTA, (4) no em dashes or banned phrases, (5) no AI structural patterns, (6) all claims about dates/defaults link to primary sources.

**Confidence:** Medium. Profile is test-drive from news-fetcher; may need refinement after first sweep.

**Next action:** Sage sweeps 18 docs + 3 READMEs for voice hygiene. Baseline: 1 "leverag*" match, 10 em dashes, emoji audit pending.

### 10. Persistent session logging rule established (Coordinator)

**Date:** 2026-05-12  
**Author:** martinopedal (via Squad coordinator)  
**Type:** Directive (permanent)  
**Status:** Active

Every session must write all in-flight work, decisions, scope, file lists, and follow-up plans to `.squad/` proactively before it ends. Sessions can break for any reason (compaction, accidental close, machine sleep, network drop), and the next session must pick up exactly where the previous one left off without re-asking the user.

**Why:** SQL todos (`.session/database.sqlite`) are session-scoped and do NOT survive across sessions. Only files under `.squad/` persist (decisions, decisions/inbox, skills, agents/*/history, log, orchestration-log).

**Rule:** Before any session-end trigger (compaction signal, user idle, multi-agent spawn, user says "end session"), Coordinator writes current state to `.squad/decisions/inbox/coordinator-{slug}.md` including:
- Decision or plan in plain prose
- Exact file paths (input and output)
- Source references (skills, other repos, MS docs links)
- Commands or scripts next session must run
- Status of each work item (planned, in-progress, blocked, done)
- Ownership assignments (Sage, Atlas, etc.)

After writing the inbox file, Coordinator spawns Scribe (background, haiku) to merge it into `.squad/decisions.md` and commit.

**For multi-agent spawns:** Write spawn manifest to inbox BEFORE launching agents. If spawn fails or session dies mid-launch, next session knows what was supposed to run.

**Source:** User directive — "always ensure everything is written into squad so we can break off sessions without issues".

### 11. Voice sweep + deck redesign spawn (closed) (Coordinator)

**Date:** 2026-05-12  
**Author:** martinopedal (via Squad coordinator)  
**Status:** Completed

Spawned Sage (docs voice sweep, chore/docs-voice-sweep) and Sage-deck (reveal.js redesign, chore/presentation-redesign) as parallel background agents on 2026-05-12T13:16Z. Both agents completed successfully. PR #49 shipped voice and hygiene sweep across 21 files per `.squad/decisions/inbox/coordinator-spawn-sage-atlas.md`. PR #50 shipped presentation redesign with Charcoal Minimal palette and pptx design principles. PR #51 logged learnings to `.squad/agents/sage/history.md`. All three PRs merged at 13:38-13:40Z. Spawn manifest closed.

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
