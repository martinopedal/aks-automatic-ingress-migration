# Infrastructure Modules

*Not an official Microsoft product. Community migration toolkit. See LICENSE.*

IaC modules for provisioning Application Gateway for Containers (AGC) base infrastructure. Both Terraform and Bicep implementations satisfy the same output contract per ADR-002.

## Terraform and Bicep Parity Contract

Every module ships in both Terraform (`infra/terraform/`) and Bicep (`infra/bicep/`). Output names, types, and semantics are identical across both stacks. This guarantees callers can switch IaC languages without rewriting wrapper code.

Parity is enforced by `scripts/validate-iac-parity.ps1`, which validates that both implementations expose outputs matching the canonical schema in each module's `outputs.schema.json`.

## Modules

### `agc/`

Provisions Application Gateway for Containers (AGC) base resources:

- `Microsoft.ServiceNetworking/trafficControllers` (AGC dataplane)
- Default frontend (FQDN used in Gateway API resources)
- Subnet association

**Implementations:**

- **Terraform:** `terraform/agc/`
- **Bicep:** `bicep/agc/`
- **Output schema:** `agc/outputs.schema.json`

## Output Contract

Each module directory contains `outputs.schema.json`, which defines the required output keys, types, and descriptions. Both Terraform and Bicep must satisfy this schema to pass parity validation.

For the canonical contract, see:

- `infra/agc/outputs.schema.json`

## Provisioning Guide

Follow the canonical provisioning runbook at `docs/runbook/02-provision-agc-base.md`.

## Parity Validation

Run the parity check to verify Terraform and Bicep outputs match:

```powershell
pwsh scripts/validate-iac-parity.ps1 `
  -SchemaPath infra/agc/outputs.schema.json `
  -TerraformModulePath infra/terraform/agc `
  -BicepModulePath infra/bicep/agc
```

This check is required before merging any changes to IaC modules. CI enforces this via `.github/workflows/iac-parity.yml`.

## Identity Scope

**This directory does NOT provision the AGC managed identity or configure Workload Identity federation.** Identity wiring is per `docs/runbook/03-identity-wiring.md` and is managed by Iris, not Forge.

The AGC modules assume the caller has already created a managed identity and assigned appropriate RBAC (`Network Contributor` on the subnet, `AppGw for Containers Configuration Manager` on the resource group). The controller installation and identity federation are separate operations outside the IaC module boundary.

## ALZ Corp Defaults

All modules follow ALZ Corp constraints:

- No public IPs created by default. AGC uses internal load balancing.
- Subnet is BYO (bring-your-own). Caller provisions the delegated subnet and passes `subnet_id`.
- Managed identity is BYO. Caller provisions and assigns RBAC separately.
- Region support: AGC is available in 23 regions. See `docs/agc-region-matrix.md` and ADR-003 for private cluster preview status.

## API Versions

Terraform uses `azapi` provider with `Microsoft.ServiceNetworking/trafficControllers@2023-11-01` (GA stable).

Bicep uses `Microsoft.ServiceNetworking/trafficControllers@2023-11-01` (GA stable).

Reference: https://learn.microsoft.com/en-us/azure/templates/microsoft.servicenetworking/trafficcontrollers (accessed 2026-04-22)
