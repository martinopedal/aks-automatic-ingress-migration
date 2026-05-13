# aks-automatic-ingress-migration

> **Not an official Microsoft product.** This is a personal community runbook. For Microsoft's supported migration utility, see [Application-Gateway-for-Containers-Migration-Utility](https://github.com/Azure/Application-Gateway-for-Containers-Migration-Utility) and the upstream [`ingress2gateway`](https://github.com/kubernetes-sigs/ingress2gateway) project ([v1.1.0 latest, April 2026](https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.1.0); [v1.0.0 GA, March 2026](https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.0.0)).

Migration toolkit and runbook for AKS Automatic clusters moving off `ingress-nginx` and the App Routing addon onto **Gateway API + Application Gateway for Containers (AGC)** before the [November 2026 critical-only date for the App Routing add-on](https://learn.microsoft.com/azure/aks/app-routing-gateway-api).

## Why this exists

Two timelines collide for AKS Automatic users:

- **March 2026**: community `ingress-nginx` project enters maintenance mode, per [Ingress NGINX retirement](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/).
- **November 2026**: Microsoft App Routing add-on (managed NGINX) stops receiving Azure support, per the caution callout in [App routing Gateway API (preview)](https://learn.microsoft.com/azure/aks/app-routing-gateway-api).

The documented migration target is Gateway API with Application Gateway for Containers. The Microsoft docs cover individual primitives. This repo covers the **end-to-end migration** for an ALZ Corp cluster: Terraform/Bicep for AGC, manifest conversion (Ingress → Gateway/HTTPRoute), traffic cutover, rollback, and the operational runbook.

## What's in scope

- AGC provisioning (Bicep + Terraform parity, BYO VNet, ALZ Corp networking).
- Ingress → Gateway API translation (annotations mapped, gotchas documented, examples).
- Coexistence and gradual cutover (run NGINX and AGC in parallel, traffic shift).
- Observability before/after.
- Operational runbook with checklists.
- Sample app: [`examples/hello-world`](./examples/hello-world/README.md) with Workload Identity, internal AGC frontend, and Gateway API resources.

## What's out of scope

- Self-hosted Kubernetes outside AKS Automatic.
- Non-Azure ingress targets (NGINX-on-VM, F5, etc.).
- Migration *to* `ingress-nginx` (this is one-way).

## Status

Pre-alpha. Backlog tracked as GitHub issues.

## Compatibility matrix

See [`docs/compatibility-matrix.md`](docs/compatibility-matrix.md). The matrix is reviewed quarterly.

## Resources

### AKS Automatic users

The standard runbook in this repo provisions AGC via Helm-installed ALB Controller, which is **not supported on AKS Automatic** per the [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq). AKS Automatic users must use the AGC ALB Controller AKS add-on (preview). See [`docs/aks-automatic-path.md`](docs/aks-automatic-path.md) for the verified enablement sequence.

### Preview features

Microsoft has shipped two preview features that change the migration story. See [`docs/preview-features.md`](docs/preview-features.md).

## Runbook security baseline

- [Threat model, AGC migration path](docs/runbook/10-threat-model.md)

## Stack

- Terraform (`azurerm` + `azapi`): primary IaC.
- Bicep: parity for Microsoft-aligned customers.
- Helm + Gateway API CRDs: Kubernetes side.
- PowerShell: operational scripts.
- Pester / `terraform validate` / `helm lint`: tests.

## Development tooling

Multi-agent dev via [Squad by Brady Gaster](https://github.com/bradygaster/squad).

## Live smoke workflow

Trigger `.github/workflows/smoke-test.yml` weekly by schedule or manually with `workflow_dispatch` to run a live smoke pass for the hello-world sample.

- Auth uses GitHub OIDC with `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` secrets.
- The workflow skips execution gracefully when secrets are missing, for example on forks.
- It captures baseline and AGC latency samples, asserts HTTP 200 plus expected body text, uploads artifacts, and then deletes the smoke resource group.

## License

MIT.
