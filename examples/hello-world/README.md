# Hello-world sample, ALZ Corp default

This sample shows the minimum path for an AKS Automatic workload on Gateway API and Application Gateway for Containers, aligned to ALZ Corp defaults.

- Workload Identity is enabled on the application ServiceAccount.
- The Gateway uses `azure-alb-internal` to avoid a public frontend IP.
- The cluster model is private API with hub egress via Azure Firewall.

## Directory layout

- `terraform/main.tf`: Terraform wrapper that consumes `infra/terraform/agc`.
- `bicep/main.bicep`: Bicep wrapper that consumes `infra/bicep/agc`.
- `manifests/`: Namespace, ServiceAccount, Deployment, Service, Gateway, and HTTPRoute.

## 1) Provision AGC base infrastructure

Terraform:

```bash
cd examples/hello-world/terraform
terraform init -backend=false
terraform plan
```

Bicep:

```bash
az deployment group what-if \
  --resource-group <rg> \
  --template-file examples/hello-world/bicep/main.bicep
```

Both wrappers reference the shared AGC modules under `infra/`. If those modules are not present on your branch yet, sync with the branch that contains issue #9 and #10 first.

## 2) Install ALB controller with Workload Identity

Follow Microsoft setup guidance for ALB Controller and Workload Identity.

- https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-managed-by-alb-controller
- https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview

Update `manifests/serviceaccount.yaml` with the actual managed identity client ID before applying resources.

## 3) Apply manifests

```bash
kubectl apply -f examples/hello-world/manifests/
```

## 4) Validate traffic through AGC frontend

Get the AGC frontend FQDN from Terraform or Bicep outputs, then test from a network path that can resolve and reach the internal frontend.

```bash
curl -sS http://<agc-frontend-fqdn>/
```

Expected response:

```text
hello from agc
```

## References

- https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/aks/landing-zone-accelerator
- https://learn.microsoft.com/en-us/azure/aks/private-clusters
- https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview
- https://gateway-api.sigs.k8s.io/
