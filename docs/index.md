# aks-automatic-ingress-migration documentation

Migration toolkit for AKS Automatic clusters moving from `ingress-nginx` and the App Routing addon to Gateway API plus Application Gateway for Containers (AGC).

## Why

- The community `ingress-nginx` project has announced retirement for **March 2026** ([kubernetes/ingress-nginx#10977](https://github.com/kubernetes/ingress-nginx/issues/10977), accessed 2026-04-22).
- The Microsoft App Routing addon drops to critical-only patches in **November 2026** ([learn.microsoft.com/azure/aks/app-routing](https://learn.microsoft.com/azure/aks/app-routing), accessed 2026-04-22).
- AKS Automatic ships ingress-nginx by default. Customers who do nothing will be on an unsupported controller.

## How to use these docs

Start at the runbook overview. Each phase is independently runnable and ends with explicit validation steps and a rollback path.

| Path | What you get |
|---|---|
| [Architecture decisions](./adr/) | ADR-001 positioning, ADR-002 Bicep+Terraform parity contract, ADR-003 AGC private cluster preview gate |
| [Migration runbook](./runbook/00-prereq-agc-availability.md) | 10-phase end-to-end runbook from assessment to rollback |
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
