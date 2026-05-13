# ADR-004: Toolkit Posture on Preview Features

*Not an official Microsoft product. Community migration toolkit. See LICENSE.*

**Status:** Accepted  
**Date:** 2026-05-13  
**Deciders:** Lead, Coordinator (per user direction)

## Context

Microsoft has shipped two preview features that materially change the AGC migration story for AKS Automatic customers:

### 1. App Routing add-on Gateway API implementation (preview)

Released as AppRoutingIstioGatewayAPIPreview feature flag. Documented at [App routing Gateway API (preview)](https://learn.microsoft.com/azure/aks/app-routing-gateway-api) (accessed 2026-05-13).

AKS Automatic clusters ship with the App Routing add-on preconfigured, per [AKS Automatic documentation](https://learn.microsoft.com/azure/aks/intro-aks-automatic) (accessed 2026-05-13). This preview lets customers adopt Gateway API without leaving the add-on or switching to AGC. Microsoft explicitly recommends this path for existing App Routing customers who want to continue using the add-on.

Enablement: `az aks update --enable-app-routing-istio`. GatewayClass name: `approuting-istio`.

Limitations (as of documentation accessed 2026-05-13):
- Cannot coexist with Istio service mesh add-on.
- Azure DNS and TLS integration via App Routing not yet supported for Gateway API mode.
- SNI passthrough unsupported.
- Egress unsupported.

Microsoft's stated positioning: App Routing is a managed control plane for Istio. Gateway API support through this add-on is the recommended path for customers already using App Routing who want to adopt Gateway API without migrating infrastructure.

### 2. AGC ALB Controller AKS add-on (preview)

Released as ManagedGatewayAPIPreview and ApplicationLoadBalancerPreview feature flags. Documented at [Deploy Application Gateway for Containers ALB Controller add-on](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon) (accessed 2026-05-13).

This preview eliminates the manual Helm installation of the ALB Controller. The add-on automatically creates:
- A managed identity named `applicationloadbalancer-<cluster-name>` in the MC_ resource group.
- A subnet named `aks-appgateway` for AGC frontends.

Enablement: `az aks update --enable-gateway-api --enable-application-load-balancer`.

This collides with our existing IaC scope. Per ADR-002, IaC modules provision AGC infrastructure (Application Gateway for Containers resource, subnet delegation, managed identity, RBAC). Identity management is covered in runbook phase 03. The add-on auto-creates identity in the node resource group (MC_), which is outside the standard scope for customer-managed identities in ALZ Corp environments.

### Preview SLA exclusion

Per [Azure preview supplemental terms](https://azure.microsoft.com/support/legal/preview-supplemental-terms/), "Previews are excluded from the SLAs and limited warranty provided for production services." AKS preview features are explicitly excluded from production support guarantees, per [AKS preview features documentation](https://learn.microsoft.com/azure/aks/draft) (accessed 2026-05-13, section on preview features).

### Toolkit's current posture

This toolkit provisions AGC infrastructure via Terraform and Bicep (ADR-002 parity contract), installs ALB Controller via Helm, and separates identity management (runbook phase 03). This worked when AGC was Helm-only. The two preview features offer alternative paths that reduce customer implementation work but carry preview risk and change identity boundaries.

Toolkit audience: AKS Automatic users planning migration before the November 2026 ingress-nginx retirement deadline. Many run production workloads under enterprise compliance and SLA requirements.

## Decision

### Question A: Should this toolkit recommend preview features to customers?

**No.** This toolkit will NOT recommend preview features as the default migration path.

Preview features are excluded from Azure SLAs and limited warranty per [Azure preview supplemental terms](https://azure.microsoft.com/support/legal/preview-supplemental-terms/). Production workloads under enterprise compliance cannot accept this risk without explicit Azure support engagement. The November 2026 deadline means customers are migrating business-critical ingress infrastructure, not experimenting with new features.

However, we WILL document preview features as alternatives with clear risk statements. Customers who need them (experimentation, non-production environments, Azure support-backed engagements) must understand the tradeoffs.

### Question B: Should this toolkit ship IaC for the AGC AKS add-on path?

**No, but document it as a first-class path for AKS Automatic users.** This toolkit will NOT ship IaC modules for the AGC ALB Controller add-on path, but will document the verified `az aks update` enablement sequence in [`docs/aks-automatic-path.md`](../aks-automatic-path.md).

Rationale for not shipping IaC:

1. The add-on auto-creates identity in the MC_ resource group. This violates the separation of concerns established in ADR-002 (IaC provisions infrastructure, identity is separate) and in runbook phase 03 (identity wiring is a separate step). Auto-created identities in node resource groups are outside customer control and harder to audit in ALZ Corp environments where RBAC and identity lifecycle are governed processes.
2. The add-on does not produce the same outputs as the Helm path (`agc_identity_client_id`, `agc_subnet_id`, customer-chosen identity name and subnet name). Wrapping it in a Terraform or Bicep module would either break the parity contract (ADR-002) or require a parallel module set with different outputs that downstream consumers must branch on. Both options dilute the toolkit's value.
3. Preview-as-code is fragile. The add-on is currently behind two preview feature flags (`ManagedGatewayAPIPreview`, `ApplicationLoadBalancerPreview`). If schema or behavior changes at GA, IaC modules become churn that re-implementers must track. Documentation of the canonical `az aks update` command is more durable.

Rationale for documenting it as a first-class AKS Automatic path:

1. Per the [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq) (accessed 2026-05-13): "Helm deployments of the ALB Controller aren't supported with AKS Automatic." The add-on is the only supported AGC path on AKS Automatic.
2. The toolkit's stated audience is AKS Automatic users planning migration before the November 2026 ingress-nginx retirement deadline (per `AGENTS.md`). Without documenting the add-on path, the toolkit cannot serve its declared audience.
3. Customers who need standard AKS retain the Helm path with full IaC. AKS Automatic customers get a documented, citation-grounded enablement sequence. Both audiences are served without diluting the IaC parity contract.

We have:

1. Created [`docs/aks-automatic-path.md`](../aks-automatic-path.md) with the verified add-on enablement sequence, identity scope notes, validation steps, and rollback. All `az` commands are quoted from the canonical [add-on quickstart](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon).
2. Marked the add-on path with explicit preview risk warnings linking to [Azure preview supplemental terms](https://azure.microsoft.com/support/legal/preview-supplemental-terms/).
3. Cross-linked from `README.md`, `docs/index.md`, `docs/preview-features.md`, and the AKS Automatic row of `docs/preview-features.md`'s migration paths table.

### Question C: Should we document the App Routing Gateway API preview?

**Yes, as a non-AGC alternative.** This toolkit focuses on AGC migration per ADR-001. App Routing with Gateway API is a separate control plane (Istio-based, not AGC). However, customers already on App Routing may ask if they need to migrate to AGC at all.

We WILL add a section to `docs/alternatives.md` (create if not exists) explaining:
1. App Routing Gateway API preview is Microsoft's recommended path for customers who want to stay on the App Routing add-on and adopt Gateway API.
2. It is NOT a migration to AGC. It keeps the same Istio control plane.
3. Limitations: no Azure DNS/TLS integration, no SNI passthrough, no egress support.
4. Customers who need AGC-specific features (WAF, private cluster GA posture, multi-region, tighter Azure integration) should follow this toolkit's AGC path.
5. Customers who only need Gateway API and are satisfied with App Routing constraints can use the preview and skip AGC migration entirely.
6. Link to [Microsoft's App Routing Gateway API documentation](https://learn.microsoft.com/azure/aks/app-routing-gateway-api).

This positions the toolkit clearly: we are the AGC path. App Routing Gateway API is a valid alternative for a subset of customers, but it is not our scope.

## Consequences

### Positive

- **Clarity for production users.** Customers understand that this toolkit prioritizes production-supported paths. Preview features are documented but not recommended.
- **Maintains IaC scope integrity.** We do not ship IaC that auto-creates identity outside customer-controlled resource groups. ADR-002 parity contract and the identity boundary in runbook phase 03 remain intact.
- **Reduces future maintenance risk.** If preview features change or are withdrawn, we have no IaC to maintain or deprecate. Documentation updates are simpler than code deprecation.
- **Positions AGC correctly.** Customers who need AGC-specific features (WAF, private cluster posture, multi-region, Azure integration) have a clear path. Customers who only need Gateway API and are satisfied with App Routing constraints can skip AGC entirely.

### Negative

- **Customers may perceive us as behind.** Microsoft is promoting preview features. Some customers will want them. We will be asked why the toolkit does not ship add-on IaC.
- **Increased documentation burden.** We must document alternatives, preview risks, and tradeoffs clearly. Runbook complexity increases.
- **Potential GA lag.** If the add-on reaches GA and becomes the dominant path, we will need a major refactor. The Helm path may become the minority use case. Mitigation: revisit this ADR quarterly and flip posture if GA + customer demand justify it.

### Neutral

- **No immediate IaC code changes.** This ADR ships one new documentation page (`docs/aks-automatic-path.md`) and updates cross-references. No Terraform, Bicep, or Helm chart changes.

## Alternatives Considered

### Ship add-on IaC now, deprecate Helm path

We could treat the add-on as the future and ship IaC for it immediately. Create a new module `terraform/modules/agc-addon` and `bicep/modules/agc-addon` that wraps `az aks update --enable-gateway-api --enable-application-load-balancer`.

Rejected because:
1. Preview features are excluded from SLA. We cannot recommend this for production migrations.
2. Output schema parity (ADR-002) breaks. The add-on auto-creates identity and subnet in MC_ resource group. Outputs will differ from the Helm path (identity name is `applicationloadbalancer-<cluster-name>` instead of customer-chosen, subnet is `aks-appgateway` instead of customer-chosen). This violates the parity contract.
3. Identity boundary violation. Runbook phase 03 manages identity separately. The add-on collapses infrastructure and identity into one step, breaking the modular runbook structure.

### Document but stay silent on recommendation

We could document both preview features neutrally without stating a clear recommendation. Let customers decide.

Rejected because this is not opinionated. The toolkit's value is clear guidance. Customers facing the November 2026 deadline need to know what the safest, most stable path is. Neutrality is indecision, and indecision slows migration.

### Recommend preview for non-prod, Helm for prod

We could recommend the add-on for dev/test environments and the Helm path for production.

Rejected because the toolkit is scoped to migration, not multi-environment lifecycle. Most customers will use one path for all environments. Documenting two recommended paths creates confusion. Better to recommend one stable path and document alternatives with clear risk statements.

### Ignore preview features entirely

We could avoid documenting them at all. Focus on Helm and GA features only.

Rejected because customers will discover the previews in Microsoft docs and ask why the toolkit does not mention them. Better to document them with clear context than to appear uninformed or out of date.

## References

- [App routing Gateway API (preview)](https://learn.microsoft.com/azure/aks/app-routing-gateway-api) (accessed 2026-05-13)
- [Deploy Application Gateway for Containers ALB Controller add-on](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon) (accessed 2026-05-13)
- [AKS Automatic overview](https://learn.microsoft.com/azure/aks/intro-aks-automatic) (accessed 2026-05-13)
- [Azure preview supplemental terms](https://azure.microsoft.com/support/legal/preview-supplemental-terms/) (accessed 2026-05-13)
- [AKS preview features documentation](https://learn.microsoft.com/azure/aks/draft) (accessed 2026-05-13)
- ADR-001: Positioning vs Upstream Tools
- ADR-002: Bicep and Terraform Parity Contract
- ADR-003: AGC Private Cluster Preview Status Gate
