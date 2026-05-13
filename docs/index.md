# aks-automatic-ingress-migration documentation

Migration toolkit for AKS Automatic clusters moving from `ingress-nginx` and the App Routing addon to Gateway API plus Application Gateway for Containers (AGC).

## Why

- The community `ingress-nginx` project enters maintenance mode in **March 2026**, per [Ingress NGINX retirement](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/).
- The Microsoft App Routing add-on (managed NGINX) stops receiving Azure support in **November 2026**, per the caution callout in [App routing Gateway API (preview)](https://learn.microsoft.com/azure/aks/app-routing-gateway-api): "the managed NGINX add-on... will stop receiving Azure support from Azure after November 2026."
- AKS Automatic ships ingress-nginx by default, per [AKS Automatic overview](https://learn.microsoft.com/azure/aks/intro-aks-automatic). Customers who do nothing will be on an unsupported controller.
- Other ingress paths: Customers using the Istio service mesh add-on as an ingress controller or AGIC (Application Gateway Ingress Controller) have separate documented paths. See [migration paths table](./preview-features.md#migration-paths-summary) and [Phase 00 prerequisites](./runbook/00-prereq-agc-availability.md#what-this-runbook-does-not-cover) for cross-links.

## How to use these docs

Start at the runbook overview. Each phase is independently runnable and ends with explicit validation steps and a rollback path.

| Path | What you get |
|---|---|
| [Architecture decisions](./adr/) | ADR-001 positioning, ADR-002 Bicep+Terraform parity contract, ADR-003 AGC private cluster preview gate, ADR-004 toolkit posture on preview features |
| [Migration runbook](./runbook/00-prereq-agc-availability.md) | 10-phase end-to-end runbook from assessment to rollback (standard AKS) |
| [AKS Automatic add-on path](./aks-automatic-path.md) | Add-on (preview) enablement sequence for AKS Automatic users, since Helm is unsupported on Automatic per the [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq) |
| [Quickstart sample](../examples/hello-world/README.md) | Smallest reproducible AGC + Gateway API + Workload Identity demo, ALZ Corp defaults |
| [Migration helper scripts](../scripts/migration/README.md) | PowerShell cmdlets for assessment, conversion, and traffic cutover |
| [Presentation deck](../presentation/README.md) | reveal.js HTML deck for internal briefings |

## Default architecture posture

All examples assume:

- ALZ Corp landing zone topology (hub-spoke with central Azure Firewall egress).
- AKS Automatic with **private API server**.
- **No public IPs** on the cluster or AGC frontend (`azure-alb-internal`).
- **Workload Identity** for in-cluster identity. No service principal secrets.
- **AGC managed identity** for the ALB controller. No SP secrets.

If your environment differs, every Terraform module and Bicep file exposes overrides. The defaults are the safest path for regulated customers.

## Validation gates

Every code change must pass these before merge:

```powershell
terraform fmt -check -recursive
terraform validate
az bicep build --file <file>
helm lint charts/*
kubectl --dry-run=client apply -f manifests/
pwsh scripts/validate-iac-parity.ps1
```

CI enforces the same gates on every PR. See [`.github/workflows/`](../.github/workflows/).

## Contributing

See [`CONTRIBUTING.md`](../CONTRIBUTING.md). Issues labeled `squad` go to Lead for triage; named owners pick up `squad:{name}` labels.
