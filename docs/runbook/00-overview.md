# Phase 00 — Overview and preflight

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
- [ ] `ingress2gateway` >= 0.3.0 is on PATH ([upstream releases](https://github.com/kubernetes-sigs/ingress2gateway/releases), accessed 2026-04-22).
- [ ] Read [ADR-003](../adr/ADR-003-agc-private-cluster-preview-gate.md). If your cluster is private and AGC private cluster support is still in preview in your region, you may need a public bastion path for validation.

## Timeline assumption

Plan for **3-6 calendar months** end-to-end for an ALZ Corp environment with realistic change windows, security review, and DR cutover testing. Phases are sized so each can be paused and resumed without leaving the cluster in an unhealthy state.

## What this runbook does NOT cover

- Migration off Application Gateway Ingress Controller (AGIC). AGIC users have a separate, simpler path documented at [learn.microsoft.com/azure/application-gateway/for-containers/migrate-from-agic-to-agc](https://learn.microsoft.com/azure/application-gateway/for-containers/migrate-from-agic-to-agc) (accessed 2026-04-22).
- Service Mesh integration (Istio, Linkerd). AGC supports `BackendTLSPolicy` for upstream mTLS but mesh sidecar coexistence is out of scope.
- Multi-cluster fleet routing.

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
