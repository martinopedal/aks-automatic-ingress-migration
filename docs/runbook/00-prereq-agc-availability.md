# Phase 00, AGC availability prerequisites

## Goal

Establish a shared mental model for the migration, confirm timelines, and verify the operator's environment is ready to begin.

## Mental model shift

| Concept | ingress-nginx world | Gateway API + AGC world |
|---|---|---|
| Routing object | `Ingress` (single resource, vendor annotations) | `Gateway` (infra owner) + `HTTPRoute` (app owner) |
| Controller | `ingress-nginx-controller` Deployment in cluster | `alb-controller` in `azure-alb-system` plus Azure-managed AGC dataplane |
| Frontend | LoadBalancer Service with public or internal IP | AGC frontend with FQDN, public or `azure-alb-internal` |
| TLS | `Ingress.spec.tls`, cert-manager | `Gateway.spec.listeners[].tls.certificateRefs` to `Secret` (Gateway API v1) |
| Annotation behaviour | NGINX-specific, snippets, lua | First-class spec fields, filters, BackendTrafficPolicy |
| Identity | SP secret in cluster typical | Workload Identity for app, managed identity for controller |

## Preflight checklist

Before starting Phase 01, confirm:

- [ ] You have **Owner** or equivalent on the AKS cluster's resource group (needed for managed identity assignments and AGC association).
- [ ] You have **Network Contributor** on the spoke VNet (needed for AGC subnet delegation).
- [ ] AKS cluster is on a supported Kubernetes version (see [AKS supported versions](https://learn.microsoft.com/azure/aks/supported-kubernetes-versions), accessed 2026-04-22).
- [ ] `kubectl`, `helm`, `az` (with `aks-preview` extension), `terraform >= 1.6`, `pwsh >= 7.4` are on PATH.
- [ ] `ingress2gateway` >= v1.0.0 ([v1.1.0 latest, April 2026](https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.1.0)) is on PATH.
- [ ] Read [ADR-003](../adr/ADR-003-agc-private-cluster-preview-gate.md). If your cluster is private and AGC private cluster support is still in preview in your region, you may need a public bastion path for validation.

**Canonical region list:** See the live list at [Application Gateway for Containers overview, Supported regions](https://learn.microsoft.com/azure/application-gateway/for-containers/overview#supported-regions). Snapshot in [`docs/agc-region-matrix.md`](../agc-region-matrix.md).

**Preview alternatives:** Microsoft has shipped two preview features that change the migration story. See [`docs/preview-features.md`](../preview-features.md) for App Routing Gateway API implementation and AGC ALB Controller AKS add-on.

## Timeline assumption

Plan for **3-6 calendar months** end-to-end for an ALZ Corp environment with realistic change windows, security review, and DR cutover testing. Phases are sized so each can be paused and resumed without leaving the cluster in an unhealthy state.

## What this runbook does NOT cover

- Migration off Application Gateway Ingress Controller (AGIC). AGIC users have a separate, simpler path documented at [learn.microsoft.com/azure/application-gateway/for-containers/migrate-from-agic-to-agc](https://learn.microsoft.com/azure/application-gateway/for-containers/migrate-from-agic-to-agc) (accessed 2026-04-22).
- Service mesh sidecar coexistence with AGC. AGC supports `BackendTLSPolicy` for upstream mTLS per the [AGC API specification](https://learn.microsoft.com/azure/application-gateway/for-containers/api-specification-kubernetes#packages) (accessed 2026-05-13), but mesh sidecar injection patterns (Istio, Linkerd) alongside AGC frontends are out of scope.
- Istio service mesh add-on used as an ingress controller. Customers using the Istio add-on for ingress (not as a full sidecar mesh) have a documented path to adopt the Istio Gateway API mode (preview, asm-1-26+) per [Configure Istio ingress with the Kubernetes Gateway API for AKS (preview)](https://learn.microsoft.com/azure/aks/istio-gateway-api) (accessed 2026-05-13), without migrating to AGC. See the migration paths table in [`docs/preview-features.md`](../preview-features.md#migration-paths-summary).
- Multi-cluster fleet routing.

## AGC platform requirements

Application Gateway for Containers requires AKS in Azure with Azure VNets. AGC is a PaaS resource (`Microsoft.ServiceNetworking/trafficControllers`) that relies on Azure-managed networking primitives and AKS-specific identity wiring.

The following platforms are **not supported**:

- **Azure Arc-enabled Kubernetes** (any non-Azure cluster connected via Arc). AGC requires Azure VNets with subnet delegation and cannot attach to clusters outside Azure.
- **AKS on Azure Local** (formerly AKS hybrid / Azure Stack HCI). AGC subnet delegation and traffic controller provisioning require AKS-in-Azure.
- **AKS Edge Essentials**. AGC is not supported on edge deployment models.
- **Self-managed Kubernetes on Azure VMs** (without AKS). AGC requires AKS-managed identity federation and control plane integration. Kubernetes clusters deployed manually on Azure VMs do not have these primitives.

**Citations:** [Application Gateway for Containers overview](https://learn.microsoft.com/azure/application-gateway/for-containers/overview) (accessed 2026-05-13) states "Azure Kubernetes Service (AKS)" as the target platform. The [ALB Controller add-on quickstart prerequisites](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon) (accessed 2026-05-13) lists only AKS-in-Azure prerequisites with no mention of Arc or Azure Local support.

## Phases at a glance

| Phase | Outcome |
|---|---|
| [01](./01-assess-current-ingress.md) | Inventory of every Ingress in the cluster with annotation risk classification |
| [02](./02-provision-agc-base.md) | AGC base infrastructure deployed via Terraform or Bicep, parity-checked |
| [03](./03-identity-wiring.md) | Workload Identity federation for the ALB controller and app workloads |
| [04](./04-translate-manifests.md) | Ingress manifests translated to Gateway + HTTPRoute via `ingress2gateway` plus manual fixes |
| [05](./05-network-and-dns.md) | Network policies, DNS strategy, and cert lifecycle aligned with the new frontend |
| [06](./06-shadow-traffic.md) | New AGC frontend serving real traffic in shadow mode for observation |
| [07](./07-cutover.md) | Production cutover, weighted or DNS-flip |
| [08](./08-decommission.md) | App Routing addon disabled, ingress-nginx Helm release removed, leftover resources cleaned |
| [09](./09-rollback.md) | Documented reverse path at any phase |

## References

- [AKS Automatic overview](https://learn.microsoft.com/azure/aks/intro-aks-automatic) (accessed 2026-04-22)
- [Application Gateway for Containers overview](https://learn.microsoft.com/azure/application-gateway/for-containers/overview) (accessed 2026-04-22)
- [Gateway API v1.0 GA announcement](https://kubernetes.io/blog/2023/10/31/gateway-api-ga/) (accessed 2026-04-22)
