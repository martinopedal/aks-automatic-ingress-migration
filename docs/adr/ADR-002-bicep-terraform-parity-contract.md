# ADR-002: Bicep + Terraform Parity Contract

**Status:** Accepted  
**Date:** 2026-04-22  
**Deciders:** Forge, Lead  

## Context

ADR-001 establishes this repository's wedge: we orchestrate upstream tools and provide ALZ Corp IaC, runbook, and samples. The wedge commits us to dual-stack examples in both Terraform (azurerm + azapi) and Bicep. Our customers split evenly between both languages. Wrapper modules, CI pipelines, and enterprise adoption patterns demand equivalence.

Drift between Bicep and Terraform breaks the wedge. If the Bicep stack outputs AGC identity client IDs under one name and the Terraform stack under another, wrapper modules cannot abstract the choice. If one stack provisions subnets and the other requires pre-existing subnets, migration scripts fail. If outputs are renamed in one stack but not the other, downstream consumers break silently.

This repository has no value if customers must maintain parallel implementations. Parity is the contract. This ADR defines what parity means and how we test it.

## Decision

**We enforce output schema equivalence, not source equivalence.**

### What Parity Means

Parity is defined at the module output boundary. For every Terraform module under `terraform/`, there must exist a Bicep module under `bicep/` with the same logical scope (e.g., `terraform/modules/agc` and `bicep/modules/agc`). Both modules must expose outputs with identical:

1. **Names.** Output keys match exactly (case-sensitive). Example: `agc_frontend_fqdn`, not `agcFrontendFqdn` in one stack and `agc_frontend_fqdn` in the other.
2. **Value semantics.** Outputs represent the same Azure resources or configuration values. Example: both stacks emit the AGC managed identity's client ID under `agc_identity_client_id`, not one emitting the identity resource ID and the other emitting the client ID.
3. **Types.** Outputs use equivalent types across both languages. Example: a Terraform `list(string)` must correspond to a Bicep `array` of strings, not a single delimited string.

Source equivalence is NOT required. Bicep and Terraform have different idioms:

- Bicep uses `existing` resources to reference pre-created resources. Terraform uses data sources.
- Bicep uses symbolic names in modules. Terraform uses resource addresses.
- Bicep supports inline RBAC assignments on resources. Terraform separates role assignments into separate resources.

Each stack should follow its language's best practices. We test outputs, not source.

### What We Test

Every module directory under `terraform/` and `bicep/` must include an `outputs.schema.json` file that declares the expected output keys, types, and descriptions. Example:

```json
{
  "agc_id": {
    "type": "string",
    "description": "Azure resource ID of the Application Gateway for Containers"
  },
  "agc_frontend_fqdn": {
    "type": "string",
    "description": "Fully qualified domain name of the AGC frontend"
  },
  "agc_identity_client_id": {
    "type": "string",
    "description": "Client ID of the AGC managed identity"
  },
  "agc_subnet_id": {
    "type": "string",
    "description": "Azure resource ID of the subnet delegated to AGC"
  }
}
```

CI validates:

1. **Schema completeness.** Both Terraform and Bicep modules expose all keys declared in `outputs.schema.json`.
2. **No drift.** Outputs present in one stack but not declared in `outputs.schema.json` fail validation (prevents undocumented drift).
3. **Type equivalence.** Terraform `string` maps to Bicep `string`, Terraform `list(string)` maps to Bicep `array`, Terraform `map(string)` maps to Bicep `object`.

We do NOT execute `terraform apply` or `az deployment group create` in CI for parity tests. We rely on `terraform output -json` against a `.tfstate` fixture and `az deployment group what-if --result-format FullResourcePayloads` or pre-validated output manifests. For modules without live deployments, contributors manually validate and document outputs in `outputs.schema.json`.

### The CI Gate

A GitHub Actions workflow `.github/workflows/parity-check.yml` runs on every PR that touches `terraform/`, `bicep/`, or `outputs.schema.json` files. Steps:

1. Discover all `outputs.schema.json` files in the repository.
2. For each schema file, parse the expected output keys.
3. For Terraform: run `terraform output -json` against test fixtures or validate the module's `outputs.tf` declares matching keys.
4. For Bicep: parse the module's `output` declarations and validate keys match.
5. Fail the build if any key is missing in one stack or undeclared in the schema.

This workflow runs before any manual review. PRs cannot merge without a passing parity check.

## Consequences

### Positive

- **Wrapper modules work.** Customers can choose Terraform or Bicep without changing their orchestration layer. A Terraform wrapper can call our Terraform modules. A Bicep wrapper can call our Bicep modules. Both produce the same outputs.
- **Predictable migration.** Customers migrating from Bicep to Terraform (or vice versa) can rely on stable output names. No breaking changes in downstream automation.
- **Documentation clarity.** Runbook steps reference outputs by name. One set of instructions works for both stacks.
- **Less drift.** CI prevents accidental divergence. Outputs cannot be renamed in one stack without updating both.

### Negative

- **Dual maintenance.** Every contributor must update both stacks. A Terraform-only change requires a Bicep translation. This slows development.
- **Provider lag.** Some Azure features lag in azurerm or Bicep resource providers. Example: AKS Automatic features often land in azapi before azurerm, and Bicep extensibility providers before native Bicep resources. We must use workarounds (azapi in Terraform, deployment scripts in Bicep) or defer features until both stacks support them.
- **Test complexity.** We must maintain `outputs.schema.json` files and validate both stacks. This adds cognitive load and CI time.

### Neutral

- **Not every file requires parity.** Terraform-specific tooling (e.g., `terraform fmt`, `tflint` configs) and Bicep-specific tooling (e.g., `bicepconfig.json`) live in their respective directories without equivalents. Only modules with outputs are subject to parity.
- **Escape hatch exists.** If a feature is only available in one stack, we document the gap in `.squad/decisions.md` with a "deferred parity" decision and a target date for resolution. This unblocks time-sensitive features while preserving the long-term contract.

## Alternatives Considered

### Source-level parity

We could require both stacks to use identical resource blocks, variable names, and structures. Rejected because this is too brittle. Bicep and Terraform have different idioms. Forcing them into the same shape hurts readability and maintainability. We care about outputs, not implementation.

### Single-stack-only with adapter

We could pick one stack (Terraform or Bicep) as the primary and generate the other using a transpiler or adapter layer. Rejected because no reliable bidirectional transpiler exists, and customers need native, idiomatic code in both languages. Generated code is hard to review and maintain.

### Feature-flag drift with deferred decisions

We keep this as an escape hatch. If a feature is only available in azapi or Bicep extensibility providers, we document the gap in `.squad/decisions.md` with a target resolution date. Example: "AGC custom health probes are azapi-only as of 2026-04-22, Bicep parity deferred to 2026-05-15 pending azurerm provider release." This prevents blocking legitimate features while preserving the parity contract as the default.

### No parity enforcement

We could document parity as a goal but not enforce it in CI. Rejected because undocumented drift is worse than no parity at all. Without enforcement, the wedge breaks silently, and customers lose trust.

## References

- [ADR-001: Positioning vs Upstream Tools](./ADR-001-positioning-vs-upstream-tools.md)
- [Terraform azurerm provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform azapi provider documentation](https://registry.terraform.io/providers/Azure/azapi/latest/docs)
- [Bicep resource reference for Application Gateway for Containers](https://learn.microsoft.com/en-us/azure/templates/microsoft.servicenetworking/trafficcontrollers)
- [Bicep extensibility providers](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-extensibility-kubernetes-provider)
- [Issue #7: Define parity test and CI gate](https://github.com/martinopedal/aks-automatic-ingress-migration/issues/7)
