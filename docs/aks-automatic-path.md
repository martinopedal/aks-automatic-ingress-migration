# AKS Automatic migration path

*Not an official Microsoft product. Community migration toolkit. See LICENSE.*

---

## Why this page exists

The standard runbook in this repo provisions AGC, installs the ALB Controller via Helm, and wires identity in three separate phases. **That sequence does not work on AKS Automatic.** The [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq) (accessed 2026-05-13) states: "Helm deployments of the ALB Controller aren't supported with AKS Automatic." The only supported AGC path on AKS Automatic is the **AGC ALB Controller AKS add-on**, which is currently in preview.

Per [ADR-004](./adr/ADR-004-toolkit-posture-on-preview-features.md), this toolkit treats preview features as documented alternatives and does not ship Terraform or Bicep modules for them. This page documents the verified AKS-add-on path using Microsoft's published commands. Customers who require production support should read the preview risk section before proceeding.

## Preview risk

The two feature flags below are preview. Per [Azure preview supplemental terms](https://azure.microsoft.com/support/legal/preview-supplemental-terms/), "Previews are excluded from the SLAs and limited warranty provided for production services." Production workloads under enterprise compliance need explicit Azure support engagement before adopting this path.

Required feature flags (Microsoft.ContainerService):

- `ManagedGatewayAPIPreview`
- `ApplicationLoadBalancerPreview`

Citation: [Quickstart: Deploy AGC ALB Controller AKS add-on](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon) (accessed 2026-05-13).

## Prerequisites

Verified against the canonical add-on quickstart (accessed 2026-05-13):

- AKS cluster in a [supported AGC region](./agc-region-matrix.md).
- Azure CNI or Azure CNI Overlay network plugin.
- OIDC issuer + Workload Identity enabled (default on AKS Automatic; confirm with `az aks show`).
- Supported AKS Kubernetes version per [supported versions](https://learn.microsoft.com/azure/aks/supported-kubernetes-versions).
- `az` CLI with `alb` and `aks-preview` extensions installed.

```bash
az extension add --name alb
az extension add --name aks-preview
```

## Steps

### 1. Register feature flags and resource providers

```bash
az feature register --namespace Microsoft.ContainerService --name ManagedGatewayAPIPreview
az feature register --namespace Microsoft.ContainerService --name ApplicationLoadBalancerPreview

az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.NetworkFunction
az provider register --namespace Microsoft.ServiceNetworking
```

Verify registration completes before proceeding:

```bash
az feature show --namespace Microsoft.ContainerService --name ManagedGatewayAPIPreview --query properties.state
az feature show --namespace Microsoft.ContainerService --name ApplicationLoadBalancerPreview --query properties.state
```

Both must report `Registered`. Re-register the resource providers after the features flip to apply the change:

```bash
az provider register --namespace Microsoft.ContainerService
```

### 2. Enable the add-on on an existing AKS Automatic cluster

```bash
AKS_NAME='<your cluster name>'
RESOURCE_GROUP='<your resource group name>'

az aks update \
  --name "${AKS_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --enable-gateway-api \
  --enable-application-load-balancer
```

The add-on auto-creates the following in the AKS node resource group (`MC_<rg>_<cluster>_<region>`), per the add-on quickstart:

- Managed identity `applicationloadbalancer-<cluster-name>` with role assignments **Network Contributor**, **AppGw for Containers Configuration Manager**, and **Reader** on the MC resource group.
- Federated identity credential `aksfic` for ServiceAccount `kube-system/alb-controller-sa`.
- Subnet `aks-appgateway` with delegation `Microsoft.ServiceNetworking/TrafficController` (when using AKS-managed VNet).

Per the same source: "It is unsupported to modify the identity or namespace when provisioning integration with the add-on." If you need a customer-controlled identity or subnet name, the add-on path is not appropriate and you should not be on AKS Automatic for this workload.

### 3. Verify ALB Controller pods

```bash
kubectl get pods -n kube-system | grep alb-controller
```

Expected: two `alb-controller-*` pods in `Running` state.

### 4. Verify GatewayClass

```bash
kubectl get gatewayclass azure-alb-external -o yaml
```

Expected: `status.conditions` contains `type: Accepted, status: "True", message: Valid GatewayClass`.

### 5. Choose a deployment strategy for AGC resources

The add-on installs the ALB Controller. The AGC resource itself (Application Gateway for Containers, Frontend, Association) needs to be created either by the controller or by you:

- **Managed by ALB controller:** controller manages AGC lifecycle from a Kubernetes `ApplicationLoadBalancer` custom resource. Quickstart: [Create AGC managed by ALB controller](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-managed-by-alb-controller).
- **Bring your own (BYO) deployment:** create the AGC resource via Azure portal, CLI, PowerShell, ARM, Terraform, or Bicep, then reference it in Kubernetes config. Quickstart: [Create AGC, BYO deployment](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-byo-deployment).

If you choose BYO on AKS Automatic, the AGC dataplane modules in this repo (`infra/terraform/agc`, `infra/bicep/agc`) can provision the AGC resource. The ALB Controller portion is the add-on.

### 6. Translate ingress manifests and apply

Follow runbook phase [04-translate-manifests.md](./runbook/04-translate-manifests.md) to convert `Ingress` to `Gateway` + `HTTPRoute` using `ingress2gateway`. The translation step is the same regardless of which install path you took.

## Validation

```bash
# ALB Controller running
kubectl get pods -n kube-system | grep alb-controller

# GatewayClass accepted
kubectl get gatewayclass azure-alb-external

# Add-on managed identity present in MC_ resource group
MC_RG=$(az aks show -g "${RESOURCE_GROUP}" -n "${AKS_NAME}" --query nodeResourceGroup -o tsv)
az identity list -g "${MC_RG}" --query "[?starts_with(name, 'applicationloadbalancer-')].{name:name, principalId:principalId}" -o table

# Federated credential
az identity federated-credential list \
  --identity-name "applicationloadbalancer-${AKS_NAME}" \
  -g "${MC_RG}" \
  --query "[?name=='aksfic']" -o table
```

## Rollback

```bash
az aks update \
  --name "${AKS_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --disable-gateway-api \
  --disable-application-load-balancer
```

This removes the ALB Controller and the add-on managed identity. Any AGC resources created by the controller via `ApplicationLoadBalancer` custom resources are also removed. BYO AGC resources are left in place and must be deleted separately.

Citation: [Quickstart: Deploy AGC ALB Controller AKS add-on, Uninstall section](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon).

## Why this path is not in the standard runbook

The standard runbook assumes:

1. Customer-controlled managed identity in a customer-chosen resource group, wired via Phase 03.
2. Helm-installed ALB Controller via Phase 02.
3. IaC-provisioned AGC resources via Terraform or Bicep modules with parity-checked outputs (ADR-002).

The add-on path collapses (1) and (2) into one `az aks update` call, places the identity in `MC_<...>` outside customer governance scope, and breaks the IaC parity contract because the add-on does not produce the same outputs (`agc_identity_client_id`, `agc_subnet_id`, etc.) as the Helm path. ADR-004 documents the rationale for not shipping IaC for the add-on path.

## References

- [AGC FAQ, AKS Automatic support statement](https://learn.microsoft.com/azure/application-gateway/for-containers/faq)
- [Quickstart: Deploy AGC ALB Controller AKS add-on (preview)](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon)
- [Create AGC, managed by ALB controller](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-managed-by-alb-controller)
- [Create AGC, bring your own deployment](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-byo-deployment)
- [Azure preview supplemental terms](https://azure.microsoft.com/support/legal/preview-supplemental-terms/)
- [AKS supported Kubernetes versions](https://learn.microsoft.com/azure/aks/supported-kubernetes-versions)
- [ADR-004: Toolkit Posture on Preview Features](./adr/ADR-004-toolkit-posture-on-preview-features.md)
- [Preview features overview](./preview-features.md)
