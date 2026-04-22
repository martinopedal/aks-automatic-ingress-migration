# ADR-001: Positioning vs Upstream Tools

**Status:** Accepted  
**Date:** 2026-04-22  
**Deciders:** Sage, Lead  

## Context

AKS Automatic users face a November 2026 deadline when Microsoft's App Routing addon with ingress-nginx will move to critical-only support, per [AKS ingress-nginx retirement guidance](https://learn.microsoft.com/en-us/azure/aks/http-application-routing-migrate). The migration path to Application Gateway for Containers (AGC) with Gateway API is well-defined in Microsoft documentation, but two upstream tools already exist in this space:

1. **[Azure/Application-Gateway-for-Containers-Migration-Utility](https://github.com/Azure/Application-Gateway-for-Containers-Migration-Utility)**  
   - Microsoft-maintained CLI tool for translating AGIC or NGINX Ingress resources to Gateway API resources compatible with AGC.
   - Supports both Bring Your Own (BYO) deployment (pre-existing AGC resource) and managed deployment (ALB Controller creates AGC).
   - Reads ingresses from YAML files or live clusters. Outputs Gateway API YAML. Read-only, does not modify clusters.
   - Ships with extensive annotation coverage for both AGIC and NGINX providers.

2. **[kubernetes-sigs/ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway) v1.0 GA**  
   - Released March 20, 2026, per [v1.0.0 release on GitHub](https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.0.0) and [Kubernetes blog announcement](https://kubernetes.io/blog/2026/03/20/ingress2gateway-1-0-release/).
   - Kubernetes SIG Network official tool for translating Ingress resources to Gateway API.
   - Vendor-neutral, supports multiple providers (NGINX, Istio, Cilium, Kong, APISIX, GCE) and emitters (standard Gateway API, provider-specific extensions).
   - Provider/emitter architecture separates ingress translation from Gateway API rendering.

Both tools are mature, well-tested, and actively maintained. Neither tool covers the full ALZ Corp end-to-end scenario for AKS Automatic users: Azure Firewall egress, no public IPs on AKS, private cluster API, workload identity for AGC, Terraform and Bicep IaC parity, sample applications with HTTPS frontends and database backends, runbook steps for real production migrations.

AKS Automatic customers in Azure Landing Zone (ALZ) Corp environments need an opinionated runbook, not just a translator. The gap is orchestration, identity, networking, and IaC, not conversion logic.

## Decision

**This repository is NOT a translator competitor.** We define our scope as:

- **ALZ Corp end-to-end runbook.** Documentation-driven migration path for AKS Automatic users in hub-spoke networks with central Azure Firewall egress, no public IPs on AKS, private cluster API.
- **Terraform and Bicep IaC parity.** Provisioning AGC, configuring workload identity for the AGC managed identity, subnet delegation, RBAC, and supporting networking (private endpoints, DNS). Every example ships in both Terraform (azurerm + azapi) and Bicep. Tests validate output equivalence.
- **Workload identity best practices.** AGC uses managed identity, not service principals. RBAC assignments follow least privilege. Secrets never stored in cluster.
- **Sample applications.** Multi-tier apps (frontend HTTPS, backend services, database tier) with Gateway API manifests, Helm charts, and pre/post migration comparison.
- **Translation by delegation.** We consume `ingress2gateway` for Ingress-to-Gateway API translation and orchestrate around it. We do not re-implement translation logic.

We remain focused on the orchestration layer that upstream tools do not cover. If Azure's migration utility or `ingress2gateway` gains ALZ Corp, IaC, or identity features in the future, we adjust scope to avoid duplication, but as of 2026-04-22, that gap is not addressed by either tool.

## Consequences

### Positive

- **Clear scope.** No confusion about our role. We orchestrate, not translate.
- **No duplicate effort.** We leverage upstream translation logic (`ingress2gateway` v1.0 GA is stable and feature-complete).
- **Tight integration.** We can wrap `ingress2gateway` in PowerShell or Terraform provisioner blocks and feed output directly to `kubectl apply` or Helm workflows.
- **Maintenance reduced.** Translation logic is owned by Kubernetes SIG Network. We only maintain runbook, IaC, and examples.

### Negative

- **Dependency on upstream cadence.** If `ingress2gateway` or Azure's migration utility has a breaking change, we must adapt. Mitigation: pin to stable v1.0.0 release and test before upgrading.
- **Risk if AGC Migration Utility expands scope.** If Microsoft ships an official ALZ Corp runbook or Terraform modules for AGC with workload identity, we may become redundant. Mitigation: collaborate early, contribute to official docs if that path emerges, archive this repo if official guidance fully covers our scope.

### Neutral

- **Two upstream tools exist.** Users may ask which one to use. Answer: `ingress2gateway` for Kubernetes-native workflows, Azure's migration utility for AGIC-to-AGC migrations. Our runbook supports both, favoring `ingress2gateway` for its vendor-neutral design.

## Alternatives Considered

### Build a competing translator

We could fork or rewrite Ingress-to-Gateway API translation logic. Rejected because `ingress2gateway` v1.0 GA is stable, well-tested, and covers 30+ annotations. Reinventing this logic is waste. We have no differentiation in translation, only in orchestration.

### Fork ingress2gateway and add ALZ Corp features

We could fork `ingress2gateway` and add Azure-specific emitters for Terraform outputs or workload identity annotations. Rejected because upstream is vendor-neutral by design. Adding Azure-specific concerns pollutes their architecture. Better to wrap the tool than fork it.

### Do nothing

We could rely on upstream tools and Microsoft documentation alone. Rejected because the gap is real. No existing resource provides an end-to-end migration path for AKS Automatic in ALZ Corp with IaC parity, workload identity, and sample apps. Customers need this runbook.

## References

- [Application Gateway for Containers overview](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview)
- [AKS App Routing addon retirement timeline](https://learn.microsoft.com/en-us/azure/aks/http-application-routing-migrate)
- [Azure/Application-Gateway-for-Containers-Migration-Utility](https://github.com/Azure/Application-Gateway-for-Containers-Migration-Utility)
- [kubernetes-sigs/ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway)
- [ingress2gateway v1.0.0 release](https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.0.0)
- [Gateway API specification](https://gateway-api.sigs.k8s.io/)
