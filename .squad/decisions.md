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

### 12. Citation grounding wave 1+2 (Coordinator)

**Date:** 2026-05-13  
**Author:** martinopedal (via Squad coordinator)  
**Status:** Completed

Following user directive "all items based on mcp learn findings and other credible documentation sources, with references" + "only use external source material in the repo" + "public material", spawned a 4-agent wave 2 to fix-forward the unsourced wave 1 work.

**Wave 1 PRs (#53-#57)** shipped fast but were not consistently grounded in MS Learn. Audit found: Sage's region matrix invented (PR #55 closed unmerged), Atlas's compatibility matrix missing v1.1.0, Forge's IaC API version stale at 2023-11-01.

**Wave 2 PRs (#58, #59, #60, #61):**
- #58 (Atlas): Compatibility matrix rewrite. Single access-date line, verified Gateway API v1.0.0 release date (2023-10-31 per GitHub), added v1.1.0 row, added two preview tool rows.
- #59 (Forge): trafficControllers ARM API bumped 2023-11-01 → 2025-01-01 across 6 IaC files. Verified GA stable, no breaking changes. terraform validate + bicep build clean. (Note: this PR also bundled Atlas + Sage + Lead drafts due to shared-cwd parallel-agent contamination, see entry 13.)
- #60 (Sage): Region matrix rewrite with verified 23-region MS list inline; created `docs/preview-features.md` covering App Routing Gateway API impl (preview) + AGC ALB Controller AKS add-on (preview); updated README Resources + runbook 00 with preview alternatives.
- #61 (Lead): ADR-004 (Proposed) "Toolkit Posture on Preview Features"; voice profile strengthened with worked ✓/✗ citation hygiene examples; ADR README index entry.

**Confirmed via MS Learn during wave 2:**
- AGC supported regions: 23 exact list per https://learn.microsoft.com/azure/application-gateway/for-containers/overview#supported-regions
- App Routing Gateway API preview feature flag: `AppRoutingIstioGatewayAPIPreview`, GatewayClass `approuting-istio`, requires Managed Gateway API + aks-preview >= 19.0.0b24
- AGC ALB Controller AKS add-on preview feature flags: `ManagedGatewayAPIPreview` + `ApplicationLoadBalancerPreview`; auto-creates `applicationloadbalancer-<cluster>` MI in MC_ resource group
- Ingress NGINX retirement: project maintenance ends March 2026 (kubernetes.dev blog); App Routing add-on Azure support ends November 2026 (app-routing-gateway-api caution callout)

**Lessons captured:**
- Parallel `task` agents share the cwd and contaminate each other's branches when they all modify files before pushing. PR #59 bundled four agents' work. Resolution: wave 3 ran sequentially.
- Voice profile required worked examples (✓ good inline verifiable / ✗ bad invented) to enforce citation discipline; abstract rules alone did not prevent fabrication.
- The legacy URL `http-application-routing-migrate` was repeatedly cited for the November 2026 cutoff. It is for the OLD HTTP application routing addon, not the modern App Routing add-on. Correct source is `app-routing-gateway-api` caution callout.

### 13. Citation grounding wave 3 (Coordinator)

**Date:** 2026-05-13  
**Author:** martinopedal (via Squad coordinator)  
**Status:** Completed

Wave 3 fixed the remaining citation defects discovered during the wave 2 audit and reconciled the toolkit with a load-bearing fact found while verifying ADR-003: per the [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq), AKS Automatic + AGC requires the AKS managed add-on (preview); Helm-installed ALB Controller is unsupported on AKS Automatic.

**Executed sequentially by @copilot directly** (no sub-agents) to avoid the wave-2 shared-cwd contamination pattern.

**Wave 3 PRs:**
- #63 ADR cleanup: ADR-001 wrong URL fix (http-application-routing-migrate → app-routing-gateway-api caution callout); ADR-003 reframed (dropped uncited Nov 2025 GA date claim, added AKS Automatic FAQ constraint, removed redundant region list, removed unsourced "Web search results" speculation, fixed Mar 2026 vs Nov 2026 conflation).
- #64 README + docs/index + runbook citations: bumped ingress2gateway 1.0 GA mentions to v1.1.0 latest with v1.0.0 GA reference; added inline citations to Mar 2026 + Nov 2026 timeline claims; replaced parent app-routing URL with app-routing-gateway-api caution callout; bumped stale `>= 0.3.0` to `>= v1.0.0`.
- #65 AKS Automatic accuracy: removed wrong claim that App Routing add-on is a migration target; added AKS Automatic row to migration paths table; reframed examples/hello-world as standard AKS only (Helm install unsupported on Automatic per FAQ); added blockquote redirects to add-on path in examples/quickstart and hello-world; presentation deck had 9 fixes including kubernetes.dev citation, app-routing-gateway-api citation, ingress2gateway v1.1.0 version freshness, "AGC private cluster preview" frame replaced with "AKS Automatic + add-on preview" frame, and the closing-slide November 2025 typo corrected to November 2026.

**Open follow-ups:**
1. Re-examine ADR-004 in light of AKS Automatic constraint: ADR-004 (Proposed) recommends NOT shipping add-on IaC, but AKS Automatic literally cannot use the toolkit's Helm-based IaC. May justify either minimal add-on enablement guidance or a scope decision that the toolkit does not target AKS Automatic until the add-on path reaches GA.
2. CONTRIBUTING.md line 25 ("Sample apps under `samples/` must run on AKS Automatic with no public IPs") is now inconsistent with wave-3 reframing; future cleanup needed.
3. `scripts/migration/README.md` references `ingress2gateway@v1.0.0` (GA marker, fine as a minimum); could note v1.1.0 latest for discoverability.

**Validation gates passed (post-merge):** terraform fmt -check -recursive, terraform validate, az bicep build, git status clean.

### 14. Citation grounding wave 4: AKS Automatic add-on path (Coordinator)

**Date:** 2026-05-13  
**Author:** martinopedal (via Squad coordinator)  
**Status:** Completed

User asked: with the AGC ALB Controller AKS add-on now in preview, should the toolkit include support? Combined with "only use external public source material" + "do not stop", the answer is yes via documentation. Wave 4 ships that as two PRs.

**Wave 4 PRs (sequential, executed by @copilot direct):**

- #67 (feat/aks-automatic-addon-runbook): Pivot ADR-004 from Proposed to Accepted with the documented-but-not-IaC posture. Ship `docs/aks-automatic-path.md` with the verified `az aks update --enable-gateway-api --enable-application-load-balancer` sequence, identity scope notes (the add-on auto-creates `applicationloadbalancer-<cluster>` MI in the MC_ resource group), validation, and rollback. All commands quoted from the canonical [add-on quickstart](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon). Cross-link from README, docs/index, preview-features. Update CONTRIBUTING.md sample-app rule to match wave 3 reframing (examples are standard AKS by default; AKS Automatic users follow new doc).
- #68 (chore/citation-housekeeping): Three remaining wave 3 follow-ups cleared. Removed fictional `blog.aks.azure.com` URL from sage charter. Added Mar 2026 + Nov 2026 citations to team.md "Deadline anchor". Added v1.1.0 latest reference to scripts/migration/README ingress2gateway snippet alongside v1.0.0 GA pin.

**Posture decision (ADR-004 Accepted):**

- Document the add-on path as first-class for AKS Automatic users.
- Do NOT ship Terraform or Bicep for the add-on path because (a) preview-as-code is fragile, (b) the add-on auto-creates identity in `MC_*` outside customer governance scope, (c) outputs do not match the Helm path's ADR-002 parity contract.

This serves both audiences without diluting the IaC parity contract: standard AKS users get the full Helm IaC path; AKS Automatic users get a documented, citation-grounded enablement sequence.

### 15. Citation grounding wave 5: voice profile sweep (Coordinator)

**Date:** 2026-05-13  
**Author:** martinopedal (via Squad coordinator)  
**Status:** Completed

Two final sweeps after wave 4.

**Wave 5 PRs:**

- #69 (chore/locale-less-urls-wave5): Stripped 19 `learn.microsoft.com/en-us/` and 1 `azure.microsoft.com/en-us/updates` locale-prefixed URLs across 7 files (manifests/README, docs/compatibility-matrix, docs/agc-region-matrix, ADR-002, ADR-003, runbook 10-threat-model, runbook 20-identity-wiring-agc-controller). Voice profile prefers locale-less URLs because learn.microsoft.com routes to the correct locale via Accept-Language headers and locale-less URLs survive Microsoft's locale-routing changes.
- #70 (chore/voice-profile-violations): Three voice profile violations found post-sweep. Replaced "production-ready" (banned phrase) in ADR-004 line 131 with "stable". Replaced em dashes in docs/agc-region-matrix.md and docs/preview-features.md with comma and parenthetical respectively.

**Repo voice state after wave 5:** zero em dashes, zero en dashes, zero banned phrases across docs/, README.md, CONTRIBUTING.md, AGENTS.md, examples/. All MS Learn URLs locale-less.

**Branch hygiene:** Pruned 14 stale remote tracking branches and 5 stale local branches after PR merges. Closed orphan `chore/wave2-lead-finalize` (was PR #62, closed redundant by Lead's reconciliation per entry 12). Repo now has `main` as the only remote head.

### 16. Wave 6: PowerShell tab and threat model expansion (Coordinator)

**Date:** 2026-05-13  
**Author:** martinopedal (via Squad coordinator)  
**Status:** Completed

User asked for "new work, PowerShell as option 2, and extend 10-threat-model.md." Wave 6 ships both as parallel PRs using isolated worktrees (one per agent) to avoid the wave 2 cwd contamination pattern.

**Wave 6 PRs (parallel, two worktrees):**

- **#72 (feat/aks-automatic-pwsh-tab, Sage on Haiku):** Add PowerShell as Option 2 alongside Azure CLI in `docs/aks-automatic-path.md`. Initial draft invented `Update-AzAksCluster -EnableGatewayAPI -EnableApplicationLoadBalancer` and `NetworkProfile.NetworkPolicy = "azure"` which do not exist in the Az.Aks module. Coordinator caught the fabrication by re-fetching the canonical [add-on quickstart](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon): the install and disable steps ship Azure CLI + Azure REST tabs only, NOT PowerShell. Sage amended to honest disclaimer prose pointing readers to the REST tab and `Invoke-AzRestMethod` wrapping. Real PowerShell tabs (sign-in, register providers, RG delete) transcribed verbatim with inline citations.

- **#73 (feat/threat-model-expansion, Sentinel on Sonnet):** Extend `docs/runbook/10-threat-model.md` from 109 to 288 lines with seven new sections: STRIDE catalog per the four trust boundaries, ALB Controller identity and RBAC (Helm vs add-on), Gateway API route attachment controls (allowedRoutes semantics), supply chain (MCR image, Helm chart pinning), logging and detection (AGC access logs, kube-audit, Defender for Containers), migration cutover risks (dual-stack, DNS TTL, decommission timing), AKS Automatic considerations (MC_ resource group identity scope per AGC FAQ). All claims grounded in MS Learn or Gateway API upstream docs with inline citations. Existing baseline sections preserved.

**Lessons:**
1. **Worktree isolation works.** Two background agents, two worktrees (`-sage-pwsh`, `-sentinel-tm`), zero cross-contamination. Pattern is now the default for parallel write-mode agents.
2. **Tab pairings on MS Learn are not uniform.** A page that ships Azure CLI tabs may pair with PowerShell on some steps and Azure REST on others. Treat each step's tab pair as a separate verification, not a global assumption.
3. **Coordinator caught the invented commands by re-fetching the canonical source.** Lesson: when an agent transcribes from MS Learn, spot-check at least one detail before merge. The quick voice grep is necessary but not sufficient; the citation accuracy check needs at least one fetch.

### 17. Wave 7: scenario coverage audit, Istio add-on ingress + AGC platform requirements (Coordinator)

**Date:** 2026-05-13  
**Author:** martinopedal (via Squad coordinator)  
**Status:** Completed

User asked: "are we covering all scenarios such as Istio without the full functionality, application routing add-on, now application gateway for containers etc? should we extend with a bare metal section too?"

Coordinator ran a Microsoft Learn MCP audit across all source and target ingress scenarios for AKS and AKS Automatic. The Learn MCP tools (`microsoft_docs_search`, `microsoft_docs_fetch`, `microsoft_code_sample_search`) became available this session via the `azure-mcp-documentation` router and replace the prior `web_fetch` workflow which collapsed tab panels.

**Audit findings:**

| Scenario | Status before wave 7 |
|---|---|
| OSS ingress-nginx (Helm) source | Covered |
| App Routing add-on (managed NGINX) source | Covered |
| AGIC source | Out of scope but linked, not in migration paths table |
| Istio service mesh add-on as ingress source | Treated only as "mesh out of scope", missing nuance |
| AGC Helm + AGC AKS add-on + BYO + ALB-managed targets | Covered |
| App Routing GW API mode (preview) target | Covered |
| Istio service mesh add-on GW API mode (preview) target | Not covered |
| Bare metal / Arc / Azure Local | Not addressed |

**Wave 7 PR:**

- **#74 (feat/scenario-coverage-istio-platform-fit, Sage on Sonnet):** Refines `docs/runbook/00-prereq-agc-availability.md` "What this runbook does NOT cover" to distinguish mesh sidecar coexistence (still out of scope) from Istio add-on as ingress (documented path with no-AGC alternative via Istio GW API mode preview). Adds new `## AGC platform requirements` section explicitly stating AGC is AKS-in-Azure only with non-fits named (Arc, Azure Local, Edge Essentials, self-managed K8s on VMs). Adds `## Istio service mesh add-on Gateway API mode (preview)` section to `docs/preview-features.md` with prerequisites (asm-1-26+, Managed Gateway API CRDs), limitations (cannot coexist with App Routing GW API impl, ConfigMap restrictions, TLSRoute SNI passthrough unsupported), and Microsoft's positioning. Adds three migration paths table rows (Istio classic, Istio GW API already, AGIC). Adds detection commands and state-to-path mapping table to `docs/runbook/01-assess-current-ingress.md` for Istio classic, Istio GW API, App Routing GW API, and existing AGC.

**Bare metal verdict:** No separate bare metal section. AGC is a PaaS (`Microsoft.ServiceNetworking/trafficControllers`) that requires Azure VNets and AKS-in-Azure. Arc-K8s, AKS on Azure Local, and AKS Edge Essentials are non-fits per the [AGC overview](https://learn.microsoft.com/azure/application-gateway/for-containers/overview) and [add-on quickstart prerequisites](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon). The non-fit callout in phase 00 prevents customer confusion without inflating scope.

**Lessons:**
1. **Learn MCP unblocked the audit.** Tab-aware fetch via `microsoft_docs_fetch` returned the AKS Automatic feature comparison page with the "three blessed ingress options" matrix verbatim, which was previously inferable but not directly cited. Use the Learn MCP for any future doc claim about MS-managed defaults or feature support boundaries.
2. **AKS Automatic ingress option triplet.** Per MS Learn, ingress on Automatic is "Preconfigured: managed NGINX via App Routing add-on. Optional: Istio service mesh add-on for AKS ingress gateway. Bring your own ingress or gateway." The toolkit now treats all three options.
3. **Mid-section H2 insertion broke document structure.** Sage's first draft put the new Istio H2 between the AGC ALB Controller add-on H2 and its own H3 children, orphaning the AGC sub-sections under the Istio H2. Coordinator caught with `grep "^##"` structural check before merge. Lesson: heading-order grep is now part of the standard PR review checklist for doc PRs that add H2s.

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
