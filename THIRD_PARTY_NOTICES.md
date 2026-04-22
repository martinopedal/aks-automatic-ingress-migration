# Third-Party Notices

This repository invokes, references, or depends on the following open-source projects. None are bundled, each must be installed or referenced separately.

---

## Application Gateway for Containers Migration Utility (Microsoft)

- **Source:** https://github.com/Azure/Application-Gateway-for-Containers-Migration-Utility
- **Copyright:** Copyright (c) Microsoft Corporation
- **License:** MIT License
- **Usage:** This repo's runbook references the official Microsoft migration utility as the primary translator for AGIC and ingress-nginx to AGC. We complement it with ALZ Corp end-to-end IaC, identity wiring, and operational runbook content.

---

## ingress2gateway (Kubernetes SIG)

- **Source:** https://github.com/kubernetes-sigs/ingress2gateway
- **Copyright:** Copyright Kubernetes Authors
- **License:** Apache License 2.0
- **Usage:** Upstream community translator (1.0 GA, March 2026) for `Ingress` to Gateway API. Referenced in the runbook for non-Azure-specific resource translation.

---

## Gateway API (Kubernetes SIG)

- **Source:** https://github.com/kubernetes-sigs/gateway-api
- **Copyright:** Copyright Kubernetes Authors
- **License:** Apache License 2.0
- **Usage:** CRDs deployed onto AKS clusters. Manifests in `manifests/` reference `Gateway`, `HTTPRoute`, `GRPCRoute`, `ReferenceGrant`.

---

## Azure Verified Modules (AVM)

- **Specification:** https://aka.ms/avm
- **Registry:** https://registry.terraform.io/namespaces/Azure
- **Copyright:** Copyright (c) Microsoft Corporation
- **License:** MIT License
- **Usage:** Where an AVM resource module exists for an Azure resource we deploy, this repo prefers the AVM module over hand-authored resources. AGC pattern composition draws on AVM conventions.

---

## HashiCorp Terraform Providers

- **azapi provider:** https://github.com/Azure/terraform-provider-azapi (MPL-2.0)
- **azurerm provider:** https://github.com/hashicorp/terraform-provider-azurerm (MPL-2.0)
- **Note:** Providers are downloaded at `terraform init` time and are not bundled.

> The Mozilla Public License 2.0 applies to the provider source files only, not to Terraform configurations that use them.

---

## Azure Bicep

- **Source:** https://github.com/Azure/bicep
- **Copyright:** Copyright (c) Microsoft Corporation
- **License:** MIT License

---

## Helm

- **Source:** https://github.com/helm/helm
- **Copyright:** Copyright The Helm Authors
- **License:** Apache License 2.0

---

## kubeconform

- **Source:** https://github.com/yannh/kubeconform
- **Copyright:** Copyright (c) 2020 Yann Hamon
- **License:** Apache License 2.0
- **Usage:** Invoked in CI to validate manifests against Kubernetes schemas.

---

## gitleaks

- **Source:** https://github.com/gitleaks/gitleaks
- **Copyright:** Copyright (c) Zachary Rice and gitleaks contributors
- **License:** MIT License
- **Usage:** Invoked in CI to scan the repository for committed secrets and identifier leaks.

---

## Squad

- **Source:** https://github.com/bradygaster/squad
- **Copyright:** Copyright (c) Brady Gaster
- **License:** MIT License
- **Usage:** Provides the agentic team orchestration scaffolding under `.squad/`.

---

# First-Party Components (aks-automatic-ingress-migration)

The following components are developed as part of this repository and licensed under the MIT License in [LICENSE](LICENSE).

## Migration plan schema (first-party)

- **Source:** `schema/migration-plan.v1.json` (planned)
- **Copyright:** Copyright (c) 2026 martinopedal
- **License:** MIT License (see [LICENSE](LICENSE))
- **Usage:** Versioned cross-repo contract consumed by `mcp-server-azure-architect`'s `ingress-migration-plan` skill.

## Bicep + Terraform AGC composition (first-party)

- **Source:** `infra/bicep/`, `infra/terraform/`
- **Copyright:** Copyright (c) 2026 martinopedal
- **License:** MIT License (see [LICENSE](LICENSE))

## Manifest catalog and sample apps (first-party)

- **Source:** `manifests/`, `samples/`, `charts/`
- **Copyright:** Copyright (c) 2026 martinopedal
- **License:** MIT License (see [LICENSE](LICENSE))

## Operational runbook (first-party)

- **Source:** `docs/runbook/`
- **Copyright:** Copyright (c) 2026 martinopedal
- **License:** MIT License (see [LICENSE](LICENSE))

Copyright (c) 2026 martinopedal. See [LICENSE](LICENSE) for the full text.
