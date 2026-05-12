# Phase 02, provision AGC base infrastructure

## Goal

Deploy the AGC dataplane (Application Load Balancer resource, frontend, association) and ALB controller subnet using the parity-checked Terraform or Bicep modules in this repo. Do not yet wire identity (Phase 03) or routes (Phase 04).

## Prerequisites

- Phase 01 complete.
- Resource group exists in the spoke subscription.
- A spoke VNet with **at least one /24 subnet free** for the AGC association ([sizing reference](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-managed-by-alb-controller#prerequisites), accessed 2026-04-22).
- Owner on the resource group and Network Contributor on the VNet.
- Read [ADR-003](../adr/ADR-003-agc-private-cluster-preview-gate.md) and confirm AGC private cluster status in your region.

## Steps

### Option A: Terraform

```bash
cd infra/terraform/agc
cat > terraform.tfvars <<EOF
location            = "westeurope"
resource_group_name = "rg-aks-prod-spoke"
agc_name            = "agc-aks-prod"
vnet_name           = "vnet-spoke-prod"
subnet_id           = "/subscriptions/.../subnets/snet-agc"
EOF

terraform init
terraform plan -out=tfplan
# review plan, then:
terraform apply tfplan
```

Outputs (parity contract per ADR-002):

```text
alb_id, alb_name, frontend_id, frontend_fqdn, association_id
```

### Option B: Bicep

```bash
cd infra/bicep/agc
az deployment group what-if \
  --resource-group rg-aks-prod-spoke \
  --template-file main.bicep \
  --parameters \
      location=westeurope \
      agcName=agc-aks-prod \
      vnetName=vnet-spoke-prod \
      subnetId=/subscriptions/.../subnets/snet-agc

# review what-if, then:
az deployment group create \
  --resource-group rg-aks-prod-spoke \
  --template-file main.bicep \
  --parameters @params.json
```

### 3. Verify parity

The repo's parity validator confirms Terraform and Bicep emit identical output names per [ADR-002](../adr/ADR-002-bicep-terraform-parity-contract.md):

```powershell
pwsh scripts/validate-iac-parity.ps1 `
  -SchemaPath infra/agc/outputs.schema.json `
  -TerraformModulePath infra/terraform/agc `
  -BicepModulePath infra/bicep/agc
```

### 4. Install the ALB Controller (no identity yet)

Identity wiring is Phase 03. Install the controller now with placeholder identity:

```bash
helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
  --namespace azure-alb-system --create-namespace \
  --version 1.6.0 \
  --set albController.podIdentity.clientID=00000000-0000-0000-0000-000000000000
```

Pods will start but log identity errors until Phase 03 completes. This is expected.

## Validation

- [ ] `az network alb show -g <rg> -n <agc-name>` returns provisioning state `Succeeded`.
- [ ] `kubectl get pods -n azure-alb-system` shows controller pods running (may be `CrashLoopBackOff` due to missing identity, that is OK).
- [ ] `terraform output frontend_fqdn` (or Bicep equivalent) returns a non-empty FQDN.
- [ ] `pwsh scripts/validate-iac-parity.ps1` exits 0.

## Rollback

```bash
# Terraform
cd infra/terraform/agc && terraform destroy

# Bicep
az deployment group create \
  --resource-group rg-aks-prod-spoke \
  --template-file main.bicep \
  --mode Complete \
  --parameters agcName=agc-aks-prod
# Or delete by RG if isolated.

helm uninstall alb-controller -n azure-alb-system
kubectl delete namespace azure-alb-system
```

No production traffic is on AGC at this phase, so destroy is safe.

## References

- [AGC quickstart, ALB controller-managed](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-managed-by-alb-controller) (accessed 2026-04-22)
- [ADR-002 Bicep+Terraform parity contract](../adr/ADR-002-bicep-terraform-parity-contract.md)
