# aks-automatic-ingress-migration

> **Not an official Microsoft product.** This is a personal community runbook. For Microsoft's supported migration utility, see [Application-Gateway-for-Containers-Migration-Utility](https://github.com/Azure/Application-Gateway-for-Containers-Migration-Utility) and the upstream [`ingress2gateway`](https://github.com/kubernetes-sigs/ingress2gateway) project (1.0 GA).

Migration toolkit and runbook for AKS Automatic clusters moving off `ingress-nginx` and the App Routing addon onto **Gateway API + Application Gateway for Containers (AGC)** before the November 2026 critical-only date.

## Why this exists

Two timelines collide for AKS Automatic users:

- **March 2026**: community `ingress-nginx` project retires.
- **November 2026**: Microsoft App Routing addon (managed NGINX) drops to critical-only patches.

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

Pre-alpha. Backlog tracked as GitHub issues with the `squad` label.

## Stack

- Terraform (`azurerm` + `azapi`): primary IaC.
- Bicep: parity for Microsoft-aligned customers.
- Helm + Gateway API CRDs: Kubernetes side.
- PowerShell: operational scripts.
- Pester / `terraform validate` / `helm lint`: tests.

## Squad

Multi-agent dev via [Squad by Brady Gaster](https://github.com/bradygaster/squad). Team in `.squad/team.md`. Routing in `.squad/routing.md`. Open `squad`-labeled issues are the live backlog.

## License

MIT.
