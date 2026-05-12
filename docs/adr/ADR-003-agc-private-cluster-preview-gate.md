# ADR-003: AGC Private Cluster Preview Status Gate

*Not an official Microsoft product. Community migration toolkit. See LICENSE.*

**Status:** Accepted  
**Date:** 2026-04-22  
**Deciders:** Sage, Sentinel

## Context

ADR-001 established ALZ Corp as the default positioning for this repository. ALZ Corp means hub-spoke networks with central Azure Firewall egress, no public IPs on AKS nodes, and private cluster API servers. This is the Microsoft-recommended architecture for enterprise AKS deployments, per [Azure Landing Zone guidance](https://learn.microsoft.com/azure/cloud-adoption-framework/scenarios/app-platform/aks/landing-zone-accelerator).

Application Gateway for Containers (AGC) is generally available, with feature support including Web Application Firewall (WAF), per [Application Gateway for Containers overview](https://learn.microsoft.com/azure/application-gateway/for-containers/overview) (accessed 2026-05-13). However, deployment paths supported on AKS Automatic and on AKS clusters with private API servers warrant explicit verification before adoption.

Per the [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq) (accessed 2026-05-13): "when using the Application Gateway for Containers ALB Controller AKS add-on, the ALB Controller can be provisioned into AKS Automatic clusters. Helm deployments of the ALB Controller aren't supported with AKS Automatic." The AKS add-on path itself requires preview feature flags `ManagedGatewayAPIPreview` and `ApplicationLoadBalancerPreview`, per [Quickstart: Deploy AGC ALB Controller AKS add-on](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon). For AKS Automatic specifically, this means the only supported AGC controller path is in preview as of the verified date.

For AGC private cluster scenarios on standard AKS (not Automatic), Microsoft documentation does not explicitly mark private cluster support as preview on the AGC overview or FAQ pages as of 2026-05-13. The previously circulated `private-cluster-support` documentation page is no longer published. Customers running ALZ Corp private clusters should verify status with their Azure account team before depending on it, and should treat it as a hard prerequisite check until Microsoft publishes a definitive GA statement.

This creates a hard prerequisite gap. Our default scenario (AKS Automatic with private cluster API) sits on at least one preview feature (the AKS add-on path), and possibly more depending on Microsoft's evolving documentation of private cluster support. Production-supported deployments typically cannot rely on preview features without accepting the [Azure preview supplemental terms](https://azure.microsoft.com/support/legal/preview-supplemental-terms/) (no SLA, no production warranty, breaking changes possible).

## Decision

We treat AGC-on-private-cluster as a **hard prerequisite block** that must be surfaced at the start of the runbook, before any infrastructure provisioning or translation steps. The runbook will not assume customers can proceed with private clusters unless they explicitly accept preview risk or wait for GA.

Concrete deliverables:

1. **Runbook prerequisite check:** Create `docs/runbook/00-prereq-agc-availability.md` as the first step in the runbook. This document will:
   - State that AGC private cluster support is in preview as of the last verified date.
   - Define what "preview" means (no SLA, potential breaking changes, not recommended for production without Azure support engagement).
   - Provide a clear decision tree: if you have a private cluster and cannot accept preview risk, stop here.
   - Document the workaround path: customers can opt for a public cluster (not ALZ Corp default), use a hybrid approach (public frontend, private backend), or engage Azure support for preview registration and guidance.
   - Link to the per-region matrix for availability nuances.

2. **Per-region availability matrix:** `docs/agc-region-matrix.md` is the canonical region list for the toolkit, sourced from the AGC overview's [Supported regions](https://learn.microsoft.com/azure/application-gateway/for-containers/overview#supported-regions) section. This ADR does not embed a duplicate region list; readers should consult that file for the verified list.

3. **Quarterly review cadence:** Sage owns a recurring task to check the [Azure Updates page](https://azure.microsoft.com/updates/) and AGC documentation quarterly. If GA is announced, `docs/runbook/00-prereq-agc-availability.md` and `docs/agc-region-matrix.md` are updated, and the runbook prerequisite check is relaxed or removed.

4. **Escalation path:** The prerequisite document includes links to:
   - [Azure support request process](https://learn.microsoft.com/azure/azure-portal/supportability/how-to-create-azure-support-request)
   - [Azure preview feature registration guidance](https://learn.microsoft.com/azure/azure-resource-manager/management/preview-features)
   - The AKS feedback forum at [feedback.azure.com](https://feedback.azure.com/d365community/forum/8ae9bf04-8326-ec11-b6e6-000d3a4f0789?&c=69637543-1829-ee11-bdf4-000d3a1ab360)

This ADR does not mandate creating the full content of `docs/runbook/00-prereq-agc-availability.md` or `docs/agc-region-matrix.md` immediately. It defines the structure and commits to producing them. Those files will be delivered under separate tracked issues.

## Consequences

### Positive

- **Transparency.** Customers understand the preview risk before investing time in migration.
- **Avoids silent production failures.** Surfacing the limitation early prevents customers from discovering it after infrastructure is deployed.
- **Clear workaround path.** Customers can make informed decisions: wait for GA, accept preview risk with Azure support, or adjust architecture (public cluster, hybrid model).
- **Maintains ALZ Corp wedge integrity.** We do not hide the default scenario's limitations. ADR-001 said private clusters are the default. This ADR says that default has a preview dependency and we document it honestly.

### Negative

- **Slows time-to-first-success.** Some customers will hit the prerequisite check and stop, delaying their migration.
- **Maintenance burden.** Sage must review the matrix quarterly and monitor Azure Updates. This is recurring effort.
- **Complexity for edge cases.** Customers in regions where AGC is not supported at all (outside the 23 listed) need separate guidance. The matrix must account for "not supported" versus "preview" versus "GA."

### Neutral

- **Creates a forcing function for GA.** If Microsoft sees customers blocked by the prerequisite check, that pressure may pull private cluster GA forward. If preview is working well, customers may accept the risk. Either outcome is information.

## Alternatives considered

### Hide the limitation behind a warning

We could include a small warning in the runbook ("private cluster support is in preview") but let customers proceed without a hard stop. Rejected because customers will encounter production issues, open support tickets, and blame the runbook for not being explicit. A hard gate is clearer.

### Only support public clusters

We could abandon ADR-001's ALZ Corp wedge and only document public cluster migrations. Rejected because it contradicts the enterprise positioning. ALZ Corp customers are the primary audience for this runbook. Ignoring their architecture is a non-starter.

### Wait for GA before launching the runbook

We could delay all runbook publication until AGC private cluster support is unambiguously GA in Microsoft documentation. Rejected because the November 2026 cutoff for App Routing's Azure support (per the [Gateway API caution callout](https://learn.microsoft.com/azure/aks/app-routing-gateway-api)) and the March 2026 community ingress-nginx maintenance end (per [Ingress NGINX retirement](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/)) do not permit waiting. Customers need migration guidance now.

### Treat preview as "good enough" and document without a gate

We could document the preview status but not call it a hard prerequisite block. Rejected because "preview" means no SLA, potential breaking changes, and lack of production support guarantees. Enterprises in ALZ Corp environments cannot risk that without explicit acceptance.

## References

- [Application Gateway for Containers overview](https://learn.microsoft.com/azure/application-gateway/for-containers/overview) (accessed 2026-05-13)
- [Application Gateway for Containers FAQ, AKS Automatic support](https://learn.microsoft.com/azure/application-gateway/for-containers/faq) (accessed 2026-05-13)
- [Quickstart: Deploy AGC ALB Controller AKS add-on (preview), feature flags](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon)
- [App routing Gateway API (preview), Azure support after November 2026 callout](https://learn.microsoft.com/azure/aks/app-routing-gateway-api)
- [Ingress NGINX retirement (March 2026)](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/)
- [Azure Landing Zone guidance for AKS](https://learn.microsoft.com/azure/cloud-adoption-framework/scenarios/app-platform/aks/landing-zone-accelerator)
- [Azure preview supplemental terms](https://azure.microsoft.com/support/legal/preview-supplemental-terms/)
- [Azure support request process](https://learn.microsoft.com/azure/azure-portal/supportability/how-to-create-azure-support-request)
- [Azure preview feature registration](https://learn.microsoft.com/azure/azure-resource-manager/management/preview-features)
- ADR-001: Positioning vs Upstream Tools (private cluster as ALZ Corp default)
- ADR-004: Toolkit Posture on Preview Features
- Issue #8: AGC private cluster preview status gate
