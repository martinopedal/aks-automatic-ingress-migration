# aks-automatic-ingress-migration

> **Not an official Microsoft product.** This is a personal community runbook. For Microsoft's supported migration utility, see [Application-Gateway-for-Containers-Migration-Utility](https://github.com/Azure/Application-Gateway-for-Containers-Migration-Utility) and the upstream [`ingress2gateway`](https://github.com/kubernetes-sigs/ingress2gateway) project ([v1.1.0 latest, April 2026](https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.1.0); [v1.0.0 GA, March 2026](https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.0.0)).

Migration toolkit and runbook for **AKS Automatic** clusters moving off `ingress-nginx` and the App Routing add-on onto **Gateway API + Application Gateway for Containers (AGC)** before the [November 2026 critical-only date for the App Routing add-on](https://learn.microsoft.com/azure/aks/app-routing-gateway-api).

## Contents

- [Why this exists](#why-this-exists)
- [Pick your path](#pick-your-path)
- [Scope](#scope)
- [Repo map](#repo-map)
- [Default architecture posture](#default-architecture-posture)
- [Compatibility and status](#compatibility-and-status)
- [Validation gates](#validation-gates)
- [Live smoke workflow](#live-smoke-workflow)
- [Security baseline](#security-baseline)
- [Stack](#stack)
- [Contributing](#contributing)
- [License](#license)

## Why this exists

Two timelines collide for AKS Automatic users:

- **March 2026**: the community `ingress-nginx` project enters maintenance mode, per [Ingress NGINX retirement](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/).
- **November 2026**: the Microsoft App Routing add-on (managed NGINX) stops receiving Azure support, per the caution callout in [App routing Gateway API (preview)](https://learn.microsoft.com/azure/aks/app-routing-gateway-api).

AKS Automatic ships `ingress-nginx` by default, per the [AKS Automatic overview](https://learn.microsoft.com/azure/aks/intro-aks-automatic), so customers who do nothing land on an unsupported controller after these dates. The documented migration target is Gateway API with Application Gateway for Containers. Microsoft docs cover individual primitives. This repo covers the **end-to-end migration** for an ALZ Corp cluster: Bicep and Terraform for AGC, manifest conversion (Ingress to Gateway and HTTPRoute), traffic cutover, rollback, and the operational runbook.

## Pick your path

| Your situation | Start here |
|---|---|
| Standard AKS, `ingress-nginx` or App Routing add-on today | [`docs/runbook/00-prereq-agc-availability.md`](docs/runbook/00-prereq-agc-availability.md) |
| **AKS Automatic** (Helm install of the ALB Controller is unsupported, per [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq)) | [`docs/aks-automatic-path.md`](docs/aks-automatic-path.md) |
| Istio service mesh add-on used as ingress | [`docs/preview-features.md`](docs/preview-features.md) (Istio Gateway API mode) |
| AGIC (Application Gateway Ingress Controller) | [`docs/preview-features.md`](docs/preview-features.md) (migration paths summary) |
| Just want to see Gateway API + AGC working in 10 minutes | [`examples/quickstart/`](examples/quickstart/README.md) |

If you are not sure which scenario applies, run [Phase 01: assess current ingress](docs/runbook/01-assess-current-ingress.md). It includes `kubectl` commands to detect what your cluster runs today.

## Scope

### In scope

- AGC dataplane provisioning ([Bicep](infra/bicep/agc/) and [Terraform](infra/terraform/agc/) parity, BYO VNet, ALZ Corp networking).
- Ingress to Gateway API translation ([annotations mapped](manifests/ingress-to-gateway/), gotchas documented, runnable [examples](examples/)).
- Coexistence and gradual cutover (run NGINX and AGC in parallel, traffic shift).
- Observability before and after migration.
- Operational runbook with checklists, validation steps, and rollback paths.
- Sample apps: [`hello-world`](examples/hello-world/README.md) (ALZ Corp defaults, Workload Identity, internal AGC frontend) and [`quickstart`](examples/quickstart/README.md) (10-minute HTTP smoke test).

### Out of scope

- Self-hosted Kubernetes outside AKS Automatic.
- Non-Azure ingress targets (NGINX-on-VM, F5, etc.).
- Migration *to* `ingress-nginx` (this is one-way).

## Repo map

```
.
├── docs/
│   ├── adr/                       Architecture Decision Records (ADR-001..004)
│   ├── runbook/                   Migration runbook: phases 00..09, threat model (10), AGC controller identity (20)
│   ├── aks-automatic-path.md      AGC ALB Controller AKS add-on (preview) enablement for AKS Automatic
│   ├── preview-features.md        Preview features that change the migration story (Istio mode, AGC add-on, AGIC)
│   ├── compatibility-matrix.md    Validated component versions, refreshed quarterly
│   ├── agc-region-matrix.md       AGC region availability summary
│   └── index.md                   Docs entry page
├── infra/
│   ├── bicep/agc/                 AGC base, Bicep
│   ├── terraform/agc/             AGC base, Terraform (parity contract in ADR-002)
│   └── agc/outputs.schema.json    Common output contract both stacks honor
├── examples/
│   ├── hello-world/               ALZ Corp defaults (private API, no public IPs, Workload Identity)
│   └── quickstart/                10-minute HTTP smoke test (no TLS, no identity)
├── manifests/
│   └── ingress-to-gateway/        Translation patterns ingress2gateway cannot fully cover (TLS, rewrites, weighted traffic)
├── scripts/
│   ├── migration/                 PowerShell module: Get-MigrationAssessment, Convert-IngressToGateway, Invoke-TrafficCutover (+ Pester tests under tests/)
│   └── validate-iac-parity.ps1    Compares Bicep and Terraform outputs against infra/agc/outputs.schema.json
├── schemas/migration-plan/v1/     JSON Schema for migration plan files (+ valid examples)
├── presentation/                  reveal.js HTML deck for internal briefings (see presentation/README.md)
└── .github/workflows/             validate, codeql, dependency-review, gitleaks, iac-parity, smoke-test, compatibility-matrix-refresh, branch-protection, copilot-auto-merge
```

## Default architecture posture

All examples assume:

- ALZ Corp landing zone topology, hub-spoke with central Azure Firewall egress.
- AKS Automatic with **private API server**.
- **No public IPs** on the cluster or AGC frontend (`azure-alb-internal` GatewayClass).
- **Workload Identity** for in-cluster identity. No service principal secrets.
- **AGC managed identity** for the ALB controller. No SP secrets.

If your environment differs, every Terraform module and Bicep file exposes overrides. The defaults are the safest path for regulated customers.

## Compatibility and status

- **Status:** Pre-alpha. Backlog tracked as [GitHub issues](https://github.com/martinopedal/aks-automatic-ingress-migration/issues).
- **Compatibility matrix:** [`docs/compatibility-matrix.md`](docs/compatibility-matrix.md), reviewed quarterly.
- **Release posture:** No semver release cadence. Pin to a specific commit SHA (Terraform module ref, Bicep module path, or script invocation). See [`CHANGELOG.md`](CHANGELOG.md) for the release posture rationale.

## Validation gates

CI runs the following on every PR via [`.github/workflows/validate.yml`](.github/workflows/validate.yml). Each step is conditional and skips when the relevant directory is absent.

| Gate | Command | Scope |
|---|---|---|
| Terraform format | `terraform -chdir=infra/terraform fmt -check -recursive` | when `infra/terraform/` exists |
| Terraform validate | `terraform -chdir=infra/terraform init -backend=false && terraform validate` | when `infra/terraform/` exists |
| Bicep build | `az bicep build --file <file>` for every `*.bicep` under `infra/bicep/` | when `infra/bicep/` exists |
| Manifest schema | `kubeconform -strict -ignore-missing-schemas` against every `*.yaml` under `manifests/` | when `manifests/` exists |
| Helm lint | `helm lint` per chart in `charts/` | when `charts/` exists (no charts ship today) |

Additional workflows: `gitleaks` (secret scanning), `codeql` (security analysis), `dependency-review` (PR dependency diff), `iac-parity` (compares Bicep vs Terraform outputs), `compatibility-matrix-refresh` (quarterly issue), `branch-protection` (lint), `copilot-auto-merge` (gates).

You can run the same gates locally:

```powershell
terraform -chdir=infra/terraform fmt -check -recursive
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate

Get-ChildItem infra/bicep -Recurse -Filter *.bicep | ForEach-Object { az bicep build --file $_.FullName }
kubeconform -strict -ignore-missing-schemas (Get-ChildItem manifests -Recurse -Filter *.yaml).FullName

pwsh scripts/validate-iac-parity.ps1
Invoke-Pester scripts/migration/tests
```

## Live smoke workflow

[`.github/workflows/smoke-test.yml`](.github/workflows/smoke-test.yml) is wired to deploy the `hello-world` sample to an ephemeral resource group, capture baseline and AGC latency probes, assert HTTP 200 with the expected body, upload artifacts, and tear the resource group down. It runs weekly on schedule (Mondays 03:00 UTC) and supports manual `workflow_dispatch`.

- **Authentication:** GitHub OIDC. Requires `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` repository secrets. The preflight job skips the run with a clear `reason` when secrets are missing, so forks no-op gracefully.
- **Current state:** the workflow looks for deploy and teardown scripts under `samples/hello-world/smoke/`, which do not yet ship in this repo (the equivalent sample lives at [`examples/hello-world/`](examples/hello-world/) and has no `smoke/` wrapper yet). The workflow therefore preflights to a `skip` job today. Tracked as a known gap; contributions welcome.

## Security baseline

- [Threat model: AGC migration path](docs/runbook/10-threat-model.md). STRIDE catalog covering ALB controller, Workload Identity, supply chain, and ALZ Corp boundaries.
- [`SECURITY.md`](SECURITY.md). Private vulnerability reporting and response posture.
- [`AI_GOVERNANCE.md`](AI_GOVERNANCE.md). AI use disclosure for contributions.
- [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md). Upstream attributions.

## Stack

- **Terraform** (`azurerm` + `azapi`): primary IaC.
- **Bicep**: parity for Microsoft-aligned customers, contract enforced by [ADR-002](docs/adr/ADR-002-bicep-terraform-parity-contract.md) and [`scripts/validate-iac-parity.ps1`](scripts/validate-iac-parity.ps1).
- **Helm + Gateway API CRDs**: Kubernetes side.
- **PowerShell** (5.1 and 7+): operational scripts under [`scripts/migration/`](scripts/migration/README.md).
- **Pester**, `terraform validate`, `bicep build`, `kubeconform`: tests.
- **reveal.js**: internal briefing deck under [`presentation/`](presentation/README.md).

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`AGENTS.md`](AGENTS.md). Key requirements:

- Sign off every commit (`git commit -s`).
- No em dashes in markdown or code comments.
- Bicep and Terraform parity is enforced by the `iac-parity` workflow and [`scripts/validate-iac-parity.ps1`](scripts/validate-iac-parity.ps1).
- Customer-facing docs include the disclaimer from [`docs/_disclaimer.md`](docs/_disclaimer.md).
- Disclose AI use in PR descriptions.

Architecture decisions: see [`docs/adr/`](docs/adr/README.md). Open backlog: see [GitHub issues](https://github.com/martinopedal/aks-automatic-ingress-migration/issues).

## License

[MIT](LICENSE).
