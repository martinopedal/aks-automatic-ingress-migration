# ADR-003: AGC Private Cluster Preview Status Gate

*Not an official Microsoft product. Community migration toolkit. See LICENSE.*

**Status:** Accepted
**Date:** 2026-04-22  
**Deciders:** Sage, Sentinel  

## Context

ADR-001 established ALZ Corp as the default positioning for this repository. ALZ Corp means hub-spoke networks with central Azure Firewall egress, no public IPs on AKS nodes, and private cluster API servers. This is the Microsoft-recommended architecture for enterprise AKS deployments, per [Azure Landing Zone guidance](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/aks/landing-zone-accelerator).

Application Gateway for Containers (AGC) reached General Availability (GA) for public AKS clusters in November 2025, including Web Application Firewall (WAF) support. However, as of April 22, 2026, AGC support for private AKS clusters is still in preview with no official GA date published by Microsoft.

This creates a hard prerequisite gap. Our default scenario (private cluster) requires a preview feature. Production-supported deployments typically cannot rely on preview features. While customers can use AGC with private clusters today, Microsoft does not guarantee backward-compatibility, SLA, or long-term support for preview functionality.

Research from Azure engineering blogs and migration guides published in early 2026 suggests GA for private cluster support is expected mid-2026, but this is not officially confirmed by Microsoft documentation. The [Azure Updates page](https://azure.microsoft.com/en-us/updates/) does not list a specific GA timeline as of this date. The [AGC overview page](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview) accessed April 22, 2026, confirms AGC is GA and lists 23 supported regions but does not distinguish public versus private cluster support status.

Additional considerations:
- Kubenet networking is not supported by AGC. Only Azure CNI (static or dynamic IP) is compatible.
- Some regions may support AGC generally but have different timelines or limitations for private cluster scenarios.
- Preview features require explicit Azure subscription preview registration in some cases.

The November 2026 deadline for ingress-nginx retirement means customers need clarity now, even if the full AGC private cluster GA occurs mid-2026.

## Decision

We treat AGC-on-private-cluster as a **hard prerequisite block** that must be surfaced at the start of the runbook, before any infrastructure provisioning or translation steps. The runbook will not assume customers can proceed with private clusters unless they explicitly accept preview risk or wait for GA.

Concrete deliverables:

1. **Runbook prerequisite check:** Create `docs/runbook/00-prereq-agc-availability.md` as the first step in the runbook. This document will:
   - State that AGC private cluster support is in preview as of the last verified date.
   - Define what "preview" means (no SLA, potential breaking changes, not recommended for production without Azure support engagement).
   - Provide a clear decision tree: if you have a private cluster and cannot accept preview risk, stop here.
   - Document the workaround path: customers can opt for a public cluster (not ALZ Corp default), use a hybrid approach (public frontend, private backend), or engage Azure support for preview registration and guidance.
   - Link to the per-region matrix for availability nuances.

2. **Per-region availability matrix:** Create `docs/agc-region-matrix.md` with:
   - A table listing the 23 AGC-supported regions (as of April 22, 2026: Australia East, Brazil South, Canada Central, Central India, Central US, East Asia, East US, East US 2, France Central, Germany West Central, Korea Central, North Central US, North Europe, Norway East, South Central US, Southeast Asia, Switzerland North, UAE North, UK South, West US, West US 2, West US 3, West Europe).
   - A column noting private cluster support status per region (initially marked "Preview, no GA date" for all).
   - A "Last Verified" date at the top of the file.
   - A note that this matrix is reviewed quarterly by Sage and updated when Microsoft publishes GA announcements.

3. **Quarterly review cadence:** Sage owns a recurring task to check the [Azure Updates page](https://azure.microsoft.com/en-us/updates/) and AGC documentation quarterly. If GA is announced, `docs/runbook/00-prereq-agc-availability.md` and `docs/agc-region-matrix.md` are updated, and the runbook prerequisite check is relaxed or removed.

4. **Escalation path:** The prerequisite document includes links to:
   - [Azure support request process](https://learn.microsoft.com/en-us/azure/azure-portal/supportability/how-to-create-azure-support-request)
   - [Azure preview feature registration guidance](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/preview-features)
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

- **Creates a forcing function for GA.** If Microsoft sees customers blocked by the prerequisite check, it may accelerate private cluster GA. Conversely, if preview is working well, customers may accept the risk. Either outcome is information.

## Alternatives Considered

### Hide the limitation behind a warning

We could include a small warning in the runbook ("private cluster support is in preview") but let customers proceed without a hard stop. Rejected because customers will encounter production issues, open support tickets, and blame the runbook for not being explicit. A hard gate is clearer.

### Only support public clusters

We could abandon ADR-001's ALZ Corp wedge and only document public cluster migrations. Rejected because it contradicts the enterprise positioning. ALZ Corp customers are the primary audience for this runbook. Ignoring their architecture is a non-starter.

### Wait for GA before launching the runbook

We could delay all runbook publication until AGC private cluster support is GA. Rejected because the November 2026 ingress-nginx deadline does not permit waiting. Customers need migration guidance now. If GA occurs mid-2026, we have months to refine the runbook post-GA.

### Treat preview as "good enough" and document without a gate

We could document the preview status but not call it a hard prerequisite block. Rejected because "preview" means no SLA, potential breaking changes, and lack of production support guarantees. Enterprises in ALZ Corp environments cannot risk that without explicit acceptance.

## References

- [Application Gateway for Containers overview](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview) (accessed 2026-04-22)
- [Azure Updates](https://azure.microsoft.com/en-us/updates/) (accessed 2026-04-22)
- [AKS App Routing addon retirement timeline](https://learn.microsoft.com/en-us/azure/aks/http-application-routing-migrate) (accessed 2026-04-22)
- [Azure Landing Zone guidance for AKS](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/aks/landing-zone-accelerator) (accessed 2026-04-22)
- [Azure support request process](https://learn.microsoft.com/en-us/azure/azure-portal/supportability/how-to-create-azure-support-request)
- [Azure preview feature registration](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/preview-features)
- ADR-001: Positioning vs Upstream Tools (private cluster as ALZ Corp default)
- Issue #8: AGC private cluster preview status gate
- Web search results: AGC private cluster GA expected mid-2026 per engineering blogs, not yet officially confirmed by Microsoft (searched 2026-04-22)
