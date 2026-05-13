# Preview Features

*Not an official Microsoft product. Community migration toolkit. See LICENSE.*

---

Microsoft has shipped two preview features that change the migration story for AKS Automatic users moving off ingress-nginx. Both are documented here for awareness. Whether this toolkit will support the preview AKS add-on path is tracked in ADR-004-toolkit-posture-on-preview-features.md.

## App Routing Gateway API implementation (preview)

The App Routing add-on now supports Gateway API in preview, using Istio as the control plane. This provides a managed migration path for existing App Routing add-on users.

Source: [Enable application routing with Gateway API (preview)](https://learn.microsoft.com/azure/aks/app-routing-gateway-api) (accessed 2026-05-12).

### What it is

App Routing add-on with Gateway API implementation. Uses Istio control plane (Istio 1.28 max as of March 2026 per the docs). GatewayClass name is `approuting-istio`.

### Prerequisites

- Feature flag: `AppRoutingIstioGatewayAPIPreview` (Microsoft.ContainerService)
- CLI extension: `aks-preview` >= 19.0.0b24
- Requires Managed Gateway API installation enabled

### CLI usage

```bash
# Enable at create
az aks create --enable-app-routing-istio --enable-managed-gateway-api ...

# Enable on existing cluster
az aks update --enable-app-routing-istio --enable-managed-gateway-api
```

### Limitations

- Cannot enable simultaneously with Istio service mesh add-on
- Azure DNS and TLS via App Routing add-on not yet supported for Gateway API
- SNI passthrough via TLSRoute unsupported
- Egress unsupported

### Microsoft's recommendation

Per the same MS Learn page: "Application routing add-on users should migrate to the application routing Gateway API implementation."

## AGC ALB Controller AKS add-on (preview)

The Application Gateway for Containers ALB Controller is available as an AKS add-on in preview. This auto-provisions the ALB controller and managed identity wiring in the cluster.

Source: [Quickstart: Deploy Application Gateway for Containers ALB controller add-on](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon) (accessed 2026-05-12).

### What it is

Managed installation of the AGC ALB Controller as an AKS add-on. Auto-creates managed identity, federated identity credential, subnet delegation, and role assignments.

### Prerequisites

- Feature flags: `ManagedGatewayAPIPreview`, `ApplicationLoadBalancerPreview` (both under Microsoft.ContainerService)
- Resource provider registrations: `Microsoft.ContainerService`, `Microsoft.Network`, `Microsoft.NetworkFunction`, `Microsoft.ServiceNetworking`
- Azure CNI or Azure CNI Overlay
- Workload identity enabled
- Supported AKS Kubernetes version
- AGC-supported region (see [agc-region-matrix.md](./agc-region-matrix.md))

### CLI usage

```bash
# Enable at create
az aks create --enable-gateway-api --enable-application-load-balancer ...

# Enable on existing cluster
az aks update --enable-gateway-api --enable-application-load-balancer
```

### What the add-on creates

- Managed identity: `applicationloadbalancer-<cluster-name>` in the MC_ resource group
- Role assignments: Network Contributor (MC RG), AppGw for Containers Configuration Manager (MC RG), Reader (MC RG)
- Federated identity credential: name `aksfic`, namespace `kube-system`, service account `alb-controller-sa`
- Subnet: `aks-appgateway` with delegation `Microsoft.ServiceNetworking/TrafficController` (when using AKS-managed VNet)

### Verification

```bash
kubectl get pods -n kube-system | grep alb-controller
# Expect 2 pods Running

kubectl get gatewayclass azure-alb-external
```

## Istio service mesh add-on Gateway API mode (preview)

The Istio service mesh add-on supports the Kubernetes Gateway API (`gateway.networking.k8s.io/v1`) in preview. This provides a Gateway API path for customers already using the Istio add-on for ingress, without migrating to AGC.

Source: [Configure Istio ingress with the Kubernetes Gateway API for AKS (preview)](https://learn.microsoft.com/azure/aks/istio-gateway-api) (accessed 2026-05-13).

### What it is

Istio service mesh add-on with Gateway API CRDs enabled. Uses `gatewayClassName: istio`. Requires Istio add-on revision `asm-1-26` or higher and the AKS Managed Gateway API CRDs add-on enabled on the cluster.

### Prerequisites

- Feature flag: `ManagedGatewayAPIPreview` (Microsoft.ContainerService)
- Istio service mesh add-on revision `asm-1-26` or higher installed on the cluster per [Deploy Istio-based service mesh add-on for AKS](https://learn.microsoft.com/azure/aks/istio-deploy-addon) (accessed 2026-05-13)
- Managed Gateway API CRDs enabled per [Enable Managed Gateway API on AKS](https://learn.microsoft.com/azure/aks/managed-gateway-api) (accessed 2026-05-13)

### Limitations

Per the [Limitations and considerations](https://learn.microsoft.com/azure/aks/istio-gateway-api#limitations-and-considerations) section (accessed 2026-05-13):

- Cannot coexist with App Routing Gateway API implementation. You must disable one before enabling the other.
- ConfigMap customizations for `Gateway` resources must fall within the resource customization allow list. See the [Istio add-on support policy](https://learn.microsoft.com/azure/aks/istio-support-policy#allowed-supported-and-blocked-customizations) (accessed 2026-05-13) for allowed, blocked, and supported features.
- TLSRoute SNI passthrough (HTTPS ingress to HTTPS services) is unsupported.
- Egress traffic management with Gateway API via Istio add-on is only supported for the [manual deployment model](https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment).

### Microsoft's positioning

This is the recommended Gateway API path for customers already on the Istio service mesh add-on who want Gateway API without migrating off Istio.

## Migration paths summary

| Starting state | Recommended path | Citation |
|---|---|---|
| App Routing add-on (managed NGINX) | App Routing Gateway API impl (preview) | [Enable application routing with Gateway API (preview)](https://learn.microsoft.com/azure/aks/app-routing-gateway-api) |
| OSS NGINX (Helm-installed) on standard AKS | Migrate directly to AGC (Helm-installed ALB Controller, GA) or to App Routing Gateway API impl (preview) | [Quickstart: Deploy AGC ALB Controller (Helm)](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller) |
| Istio service mesh add-on, classic Istio ingress (VirtualService + Gateway) | Stay on Istio, enable Gateway API mode (preview, asm-1-26+) | [Configure Istio ingress with the Kubernetes Gateway API for AKS (preview)](https://learn.microsoft.com/azure/aks/istio-gateway-api) |
| Istio service mesh add-on already on Gateway API mode | No migration needed (already on Gateway API). Optionally consolidate to AGC if AGC-specific features (WAF, multi-region, Azure integration) are required | n/a (already on target API) |
| AGIC (Application Gateway Ingress Controller) on standard AKS | Microsoft-published AGIC-to-AGC migration | [Migrate from AGIC to AGC](https://learn.microsoft.com/azure/application-gateway/for-containers/migrate-from-agic-to-agc) |
| Adopting AGC on standard AKS | Helm-based ALB Controller (GA) OR AGC AKS add-on (preview) | [Quickstart: Deploy AGC ALB Controller AKS add-on](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon) |
| Adopting AGC on **AKS Automatic** | **AGC AKS add-on (preview) only** (Helm install is unsupported on Automatic) | [AGC FAQ, AKS Automatic support](https://learn.microsoft.com/azure/application-gateway/for-containers/faq) |

Note that the AKS Automatic + AGC path requires preview feature flags `ManagedGatewayAPIPreview` and `ApplicationLoadBalancerPreview`. Per ADR-004, this toolkit treats preview features as documented alternatives and does not recommend them as the primary production path.

## AGC platform support

Application Gateway for Containers is supported only on **AKS in Azure**. AGC requires Azure VNets with subnet delegation (`Microsoft.ServiceNetworking/TrafficController`) and AKS-managed identity wiring.

The following platforms are **not supported**:

- Azure Arc-enabled Kubernetes (any non-Azure cluster connected via Arc)
- AKS on Azure Local (formerly AKS hybrid / Azure Stack HCI)
- AKS Edge Essentials
- Self-managed Kubernetes on Azure VMs (without AKS)

**Citations:** [Application Gateway for Containers overview](https://learn.microsoft.com/azure/application-gateway/for-containers/overview) (accessed 2026-05-13) and [ALB Controller add-on quickstart prerequisites](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon) (accessed 2026-05-13).

For more details, see [`docs/runbook/00-prereq-agc-availability.md#agc-platform-requirements`](./runbook/00-prereq-agc-availability.md#agc-platform-requirements).

## Toolkit posture

This toolkit ships Helm-based AGC IaC, which is supported only for **standard AKS** (not AKS Automatic) per the FAQ above. For AKS Automatic users, the toolkit documents the AGC ALB Controller add-on (preview) enablement sequence in [`docs/aks-automatic-path.md`](./aks-automatic-path.md). Per [ADR-004](./adr/ADR-004-toolkit-posture-on-preview-features.md), the toolkit does not ship Terraform or Bicep modules for the add-on path because preview-as-code is fragile and the add-on auto-creates identity outside customer-controlled scope.

## References

- [Enable application routing with Gateway API (preview)](https://learn.microsoft.com/azure/aks/app-routing-gateway-api)
- [Quickstart: Deploy AGC ALB Controller AKS add-on (preview)](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon)
- [Quickstart: Deploy AGC ALB Controller via Helm (GA)](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller)
- [Application Gateway for Containers overview](https://learn.microsoft.com/azure/application-gateway/for-containers/overview)
- [Application Gateway for Containers FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq)
- [Ingress NGINX maintenance ends March 2026](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/)
