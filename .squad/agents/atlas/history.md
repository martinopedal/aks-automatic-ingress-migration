# Atlas history

Activity log for Atlas (Kubernetes manifests, Gateway API translation, Helm).

## Learnings

### 2026-05-12: Compatibility matrix audit and rewrite (PR #58)

**Task:** Fix audit findings in `docs/compatibility-matrix.md` and cite ingress2gateway v1.1.0 and new preview tools.

**Audit findings:**
1. "Access date: 2026-05-12" duplicated in every row. Moved to single top-level metadata line.
2. ingress2gateway v1.0.0 listed, but v1.1.0 (2026-04-29, latest stable) missing. Added with inline citations for both releases.
3. Gateway API v1.0.0 release date listed as "2024-10-30" with no source. Verified via GitHub API and corrected to "2023-10-31T16:40:39Z" (published_at from https://api.github.com/repos/kubernetes-sigs/gateway-api/releases/tags/v1.0.0).
4. App Routing Gateway API impl (preview) missing. Added with GatewayClass `approuting-istio`, requirements (aks-preview >= 19.0.0b24, Istio 1.28+ control plane) from https://learn.microsoft.com/azure/aks/app-routing-gateway-api.
5. AGC ALB Controller AKS add-on (preview) missing. Added with prerequisites (Azure CNI + Workload Identity) from https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon.
6. ingress-nginx legacy row had no retirement link. Added March 2026 maintenance end date from https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/.

**Key learning:** Every external claim must be cited inline near the claim, not parked in a global "Sources" section. Access dates belong once at the top, not per row. Dates especially must be verified from primary sources (GitHub API for release timestamps, MS Learn for feature docs).

**Validation:** All claims now traced to primary sources. No invented dates. Table reformatted with Status column for clarity (GA, Preview, EOL).

**PR #58:** Opened with full citations in commit message and PR body per voice profile and decision #4 (officialness, citation policy).

### 2026-05-12: Presentation deck redesign deferred

**Task:** Redesign reveal.js deck (`presentation/index.html`) per pptx skill design principles.

**Target file:** `presentation/index.html` (single-file reveal.js, 29 KB, CDN-loaded, no build step).

**Design requirements:**
1. Read `.squad/skills/voice-profile/SKILL.md` first, then global `pptx` skill at `~/.copilot/skills/pptx/SKILL.md` (Design Ideas section, color palettes, typography table), and `C:\git\dnb-foundry-agent-demo\.squad\skills\demo-deck-structure\SKILL.md` for story arc.
2. Pick palette appropriate to topic. AKS migration suggests `Ocean Gradient` (`065A82` / `1C7293` / `21295C`) or `Charcoal Minimal` (`36454F` / `F2F2F2` / `212121`). Pick one. Commit to it.
3. Dominance: one color 60-70% visual weight, one or two supporting tones, one accent.
4. Sandwich structure: dark title/conclusion slides, light content slides. Or go dark throughout for premium feel.
5. Visual motif: pick one and repeat on every slide (thin colored corner accent, icon-in-circle for section markers, left-edge timeline rail). Consistency across all slides.
6. Typography pairing: header/body pair from pptx skill. Workable pairs: `Georgia` header + `Calibri` body, `Cambria` + `Calibri`, `Arial Black` + `Arial`, or system stack with weight contrast.
7. Every slide gets at least one visual element. No text-only slides. Icons, callout boxes, side-by-side comparisons, large stat callouts (60-72pt), timelines, process flows. Use unicode glyphs sparingly (no emojis, but boxes/arrows for flow diagrams acceptable).
8. Layout variation across slides: two-column, icon+text rows, 2x2 grid, half-bleed image with overlay. Do not repeat same layout twice in a row.
9. **NEVER add accent line under titles.** This is a known AI-tell per pptx skill. Use whitespace or background color instead.
10. Apply voice rules to slide copy. Strip em dashes, AI phrases. Open slides with the actual point, not topic introduction.
11. Keep single-file reveal.js with CDN imports. No build step. Speaker notes in `<aside class="notes">` stay.
12. Story arc: keep all current content (10-phase runbook, AGC mental model, retirement timeline, ALZ Corp posture). Polish visual treatment.

**Slide copy tone:**
- No tricolons in titles.
- No bold-heading-list filler.
- Slide titles sentence-case, not Title Case.
- Cut every "Why X matters" slide that does not answer with specific number, incident, or constraint.
- Speaker notes carry depth. Slides carry punch.

**Next session:** Atlas renders deck locally, inspects at least three slides visually before declaring done. Coordinate with Sage on shared docs/presentation scope.

### 2026-05-12: Quickstart example, compatibility matrix, manifests README

**PR #56** merged. Addressed gaps #1, #8 (manifests half), #10.

**Files created:**
- `examples/quickstart/`: HTTP-only smoke test per decision #1. Terraform AGC module call (`infra/terraform/agc`), Gateway API v1 manifests (Gateway + HTTPRoute), Kustomize structure. Backend: `nginxinc/nginx-unprivileged:latest` on port 8080.
- `examples/quickstart/infra/main.tf`: Module wrapper with defaults (`quickstart-agc` name, `azure-alb-external` gatewayClassName).
- `examples/quickstart/manifests/`: namespace, deployment, service, gateway, httproute, kustomization.yaml.
- `docs/compatibility-matrix.md`: Populated with component versions and cited sources (AKS Automatic 1.30+, Gateway API v1 GA from v1.0.0 (2024-10-30), AGC ALB Controller latest stable, ingress2gateway v1.0.0+ from 2026-03-20 release, ingress-nginx reference only).
- `manifests/README.md`: Top-level navigation for manifests/, links to `ingress-to-gateway/` catalog and `docs/runbook/04-translate-manifests.md`.

**Decisions made:**
- gatewayClassName: `azure-alb-external` (public frontend) for quickstart smoke test. `azure-alb-internal` is ALZ Corp default per `examples/hello-world/`.
- Validation strategy: Terraform `init + validate` passed locally. Manifest validation deferred to CI kubeconform (no live cluster available locally, kubectl --dry-run=client requires API server for CRD schemas).
- ingress2gateway version reference: v1.0.0 baseline per Kubernetes blog (2026-03-20). Actual release tag link: <https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.0.0>.

**Learnings:**
- The AGC module (`infra/terraform/agc`) requires `name`, `resource_group_name`, `subnet_id` (delegated to `Microsoft.ServiceNetworking/trafficControllers`), optional `location` and `tags`.
- Gateway API v1 CRDs promoted to GA in Gateway API v1.0.0 release (2024-10-30). AKS Automatic 1.30+ recommended for stable support (Kubernetes 1.29 promoted Gateway/HTTPRoute to v1).
- CI manifest validation uses kubeconform with `--ignore-missing-schemas` (`.github/workflows/validate.yml`). This avoids blocking on AGC-specific CRDs not in kubeconform's built-in schema registry.
- kubectl --dry-run=client without a live cluster falls back to syntax-only validation (no API server OpenAPI schema fetch).
