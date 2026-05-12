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

## Migration paths summary

| Starting state | Microsoft's recommended path | Citation |
|---|---|---|
| App Routing add-on (NGINX) | App Routing Gateway API impl (preview) | [Enable application routing with Gateway API (preview)](https://learn.microsoft.com/azure/aks/app-routing-gateway-api) |
| OSS NGINX (helm-installed) | Either: (a) move to App Routing add-on NGINX through Nov 2026; (b) move to App Routing Gateway API impl; (c) move to AGC | [Enable application routing with Gateway API (preview)](https://learn.microsoft.com/azure/aks/app-routing-gateway-api) |
| Adopting AGC fresh | Helm-based ALB Controller (GA) OR AGC AKS add-on (preview) | [Quickstart: Deploy Application Gateway for Containers ALB controller add-on](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon) |

## Toolkit posture

This toolkit currently ships Helm-based AGC IaC. The preview AKS add-on is documented for awareness. Whether this toolkit will support that path is tracked in ADR-004-toolkit-posture-on-preview-features.md (Lead is drafting concurrently).

## References

- [Enable application routing with Gateway API (preview)](https://learn.microsoft.com/azure/aks/app-routing-gateway-api)
- [Quickstart: Deploy Application Gateway for Containers ALB controller add-on](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon)
- [Application Gateway for Containers overview](https://learn.microsoft.com/azure/application-gateway/for-containers/overview)
- [Ingress NGINX maintenance ends March 2026](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/)
