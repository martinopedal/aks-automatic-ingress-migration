# Sentinel history

Activity log for Sentinel (Security Reviewer).

## Learnings

### 2026-05-13: Threat model expansion (PR #TBD)

**Task:** Extend `docs/runbook/10-threat-model.md` from a one-page baseline to a working threat model covering the AGC migration path end-to-end.

**Approach:**
- Preserved the existing six baseline sections (Scope, Trust boundaries, NSG/firewall, mTLS, Key risks table, Checklist) without edits beyond the date.
- Added seven new sections in this order: AKS Automatic considerations, Threat catalog by trust boundary (STRIDE per the four boundaries), ALB Controller identity and RBAC, Gateway API route attachment controls, Supply chain, Logging and detection, Migration cutover risks.
- STRIDE catalog uses one row per category per boundary (4 boundaries x 6 categories = 24 entries). Each row pairs a concrete threat scenario with a specific mitigation and inline citation.

**Sources cited (all verified by web fetch where dynamic content matters):**
- AGC FAQ (verified the AKS Automatic helm-not-supported quote, TLS 1.2 minimum claim, unique identity per controller claim).
- Gateway API security model (`/concepts/security/`, the `/concepts/security-model/` URL now redirects there). Verified `from: All` is documented as insecure and hostname conflict resolution is first-come-first-served on `creationTimestamp`.
- Gateway API HTTPRoute reference for `parentRefs` and listener attachment semantics.
- AGC overview, AGC components, AGC monitoring, AGC ALB Controller release notes.
- AKS landing zone accelerator, AKS pod security on Azure Policy, AKS network policies, AKS limit egress traffic, AKS resource logs.
- Workload Identity overview.
- Microsoft Defender for Containers introduction.
- ADR-003 and ADR-004 (cross-references for preview status and identity scope).

**Voice profile rules followed:**
- No em dashes (verified with U+2014 grep, zero hits).
- No en dashes (verified with U+2013 grep, zero hits).
- No banned phrases (verified `leveraging`, `seamless`, `robust`, `production-ready`, `comprehensive`, `unlock`, `elevate`, `empower`, `streamline`, `enterprise-grade`).
- Locale-less URLs throughout (no `/en-us/`).
- Citations inline near each claim, not parked in a References section.

**Specific threat callouts I want to remember for future reviews:**
- ApplicationLoadBalancer CR is a privilege escalation surface: anyone with `create` on `applicationloadbalancers.alb.networking.azure.io` can ask the controller to attach to a frontend in the customer's subscription. Lock down via Kubernetes RBAC.
- Add-on path on AKS Automatic auto-creates the controller managed identity in `MC_<rg>_<cluster>_<region>` outside customer's normal RBAC scope. Track by principalId, not by RG, because RG can be recreated.
- `allowedRoutes.namespaces.from: All` plus first-come-first-served hostname resolution = potential hostname hijack across namespaces. Use `Selector` with `kubernetes.io/metadata.name`, never custom labels.
- Token-leak blast radius for the ALB Controller is bounded by the role assignment scope. Stick to `AppGwForContainersConfigurationManager`. Granting Contributor at RG widens substantially.

**File metrics:**
- Before: 109 lines, ~5.5 KB.
- After: 288 lines, ~22 KB.

**PR:** See decisions inbox entry; PR number captured in summary returned to Coordinator.
