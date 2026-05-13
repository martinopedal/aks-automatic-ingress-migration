# Squad Decisions

## Active Decisions

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

### 18. Wave 8: Squad attribution removal from customer-facing docs (Sage)

**Date:** 2026-05-13  
**Author:** martinopedal (via Squad coordinator)  
**Status:** Completed

User reported: "docs/ should not leak internal squad info." 8 customer-facing docs/ files leaked internal agent names (Sage, Sentinel, Iris, Forge, Atlas, Lead) and references to .squad/* paths. External readers do not know who these agents are. The toolkit is positioned as a community project. Squad attribution belongs in .squad/, not in customer-facing docs/.

**Wave 8 PR:**

- **#76 (docs/squad-attribution-removal, Sage on Haiku):** Sanitize squad attribution from 8 docs/ files. Replace cast names with role-neutral phrasing ("Toolkit maintainers", runbook phase references). Squad attribution remains in .squad/ where it belongs. Changes:
  1. docs/adr/ADR-001-positioning-vs-upstream-tools.md: Deciders "Sage, Lead" → "Toolkit maintainers"
  2. docs/adr/ADR-002-bicep-terraform-parity-contract.md: Deciders "Forge, Lead" → "Toolkit maintainers"; removed two .squad/decisions.md references
  3. docs/adr/ADR-003-agc-private-cluster-preview-gate.md: Deciders "Sage, Sentinel" → "Toolkit maintainers"; "Sage owns" → "Toolkit maintainers run"
  4. docs/adr/ADR-004-toolkit-posture-on-preview-features.md: "Iris's domain per runbook phase 03" → "covered in runbook phase 03" (5 instances)
  5. docs/adr/README.md: Removed .squad/decisions.md link
  6. docs/compatibility-matrix.md: Dropped "Owner: Atlas" line
  7. docs/runbook/10-threat-model.md: Dropped "Owner: Sentinel" line
  8. docs/runbook/20-identity-wiring-agc-controller.md: Dropped "Owner: Iris" line

Verification: Grep across docs/ for squad agent names and .squad/ path references yields zero matches (checked 2026-05-13).

**Rationale:**

1. External readers do not care who authored which section. Role attribution is internal coordination data that confuses external contributors.
2. "Toolkit maintainers" is the correct neutral phrase. Preserves accountability without leaking internal agent names.
3. Runbook phase references replace agent domain claims. Phase numbers are public API; agent names are internal.
4. .squad/* path references must be replaced with neutral phrasing. Content preserved, internal path dropped.

**Consequences:**

Positive: docs/ is now contributor-friendly. External readers see a community toolkit, not an internal agent cast. Squad attribution remains in .squad/ where it is useful for internal coordination. Runbook phase references are more durable than agent names (phases do not change if squad membership changes).

Negative: Contributors may still copy-paste from .squad/ files into docs/ and accidentally reintroduce squad attribution. Requires vigilance in PR review.

**Lessons:**

1. Separating internal coordination (squad/) from external docs (docs/) prevents information leakage. The boundary is now explicit.
2. Voice profile role-neutral phrasing enables this separation cleanly. "Toolkit maintainers" is direct, accurate, and non-leaky.
3. Runbook phase references (01, 02, 03...) are more stable identifiers than agent names. Future squad changes do not require doc rewrites.

**Related:**

- PR #76: https://github.com/martinopedal/aks-automatic-ingress-migration/pull/76
- .squad/agents/sage/history.md: Wave 8 entry logged
