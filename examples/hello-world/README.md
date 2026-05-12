# hello-world sample, ALZ Corp defaults

This sample shows the minimum path for a **standard AKS** workload on Gateway API and Application Gateway for Containers, aligned to ALZ Corp defaults.

- Workload Identity is enabled on the application ServiceAccount.
- The Gateway uses `azure-alb-internal` to avoid a public frontend IP.
- The cluster model is private API with hub egress via Azure Firewall.

> **AKS Automatic note:** This sample installs the ALB Controller via Helm into `azure-alb-system`. Per the [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq) (accessed 2026-05-13): "Helm deployments of the ALB Controller aren't supported with AKS Automatic." AKS Automatic users must instead enable the [AGC ALB Controller AKS add-on (preview)](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon) and skip step 2 below; see [`docs/preview-features.md`](../../docs/preview-features.md) and [ADR-004](../../docs/adr/ADR-004-toolkit-posture-on-preview-features.md) for the trade-offs.

## Directory layout

- `terraform/main.tf`: Terraform wrapper that consumes `infra/terraform/agc`.
- `bicep/main.bicep`: Bicep wrapper that consumes `infra/bicep/agc`.
- `manifests/`: Namespace, ServiceAccount, Deployment, Service, Gateway, and HTTPRoute.

## 1) Plan AGC base infrastructure changes (read-only)

Terraform:

```bash
cd <repo-root>/examples/hello-world/terraform
terraform init
terraform plan
```

Bicep:

```bash
az deployment group what-if \
  --resource-group <rg> \
  --template-file examples/hello-world/bicep/main.bicep
```

Both wrappers reference the shared AGC modules under `infra/`. If you copy this sample outside this repository, update the module paths to your local AGC base module locations.

## 2) Install ALB controller with Workload Identity

Complete these tasks before you apply the sample manifests:

1. Create the AGC managed identity and configure Workload Identity federation per `docs/runbook/03-identity-wiring.md`. The IaC modules in this sample provision the AGC dataplane but do not create the identity. Identity wiring is Iris's domain per project scope decisions.
2. Install the ALB Controller in `azure-alb-system` and configure Workload Identity federation for `system:serviceaccount:azure-alb-system:alb-controller-sa` to the AGC managed identity client ID.
3. Confirm the controller is healthy: `kubectl get pods -n azure-alb-system`.

- https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-managed-by-alb-controller
- https://learn.microsoft.com/azure/aks/workload-identity-overview

Update `manifests/serviceaccount.yaml` with the actual managed identity client ID before applying resources.

## 3) Apply manifests

```bash
kubectl apply -f examples/hello-world/manifests/
```

## 4) Validate traffic through AGC frontend

Get the AGC frontend FQDN from Terraform or Bicep outputs, then test from a network path that can resolve and reach the internal frontend.

Terraform output example:

```bash
cd <repo-root>/examples/hello-world/terraform
terraform output -raw agc_frontend_fqdn
```

Bicep deployment output example:

```bash
az deployment group show \
  --name agc-base \
  --resource-group <rg> \
  --query properties.outputs.agc_frontend_fqdn.value \
  -o tsv
```

```bash
curl -sS http://<agc-frontend-fqdn>/
```

Expected response:

```text
hello from AGC
```

## References

- https://learn.microsoft.com/azure/cloud-adoption-framework/scenarios/app-platform/aks/landing-zone-accelerator
- https://learn.microsoft.com/azure/aks/private-clusters
- https://learn.microsoft.com/azure/application-gateway/for-containers/overview
- https://learn.microsoft.com/azure/application-gateway/for-containers/faq
- https://gateway-api.sigs.k8s.io/
