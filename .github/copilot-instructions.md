# Copilot Instructions — aks-automatic-ingress-migration

## Project

Migration toolkit for AKS Automatic clusters moving from `ingress-nginx` / App Routing addon to Gateway API + Application Gateway for Containers (AGC).

## Style

- No em dashes. Use periods or commas.
- Concise, direct prose. No marketing voice.
- Code examples are minimal but runnable.
- Cite MS docs or upstream GitHub for any version, date, or default-behavior claim.

## Stack

- **IaC:** Terraform (`azurerm`, `azapi`) + Bicep parity.
- **Kubernetes:** Gateway API CRDs (`v1`), AGC controller, Helm charts.
- **Scripts:** PowerShell 7+.
- **Tests:** `terraform validate`, `helm lint`, `kubectl --dry-run`, Pester for PowerShell.

## Architecture rules

- Default network posture: ALZ Corp hub-spoke, central Azure Firewall egress, no public IPs on AKS, private cluster API.
- Default identity: Workload Identity (no service principal secrets in cluster).
- AGC managed identity, never SP secrets.
- Outputs from Terraform and Bicep must be name-equivalent to enable wrapper modules.

## Squad

Read `.squad/team.md` and `.squad/routing.md`. Use the `squad` label on issues for triage; named members pick up `squad:{name}` labels.

## Commit and PR conventions

- Commit message: imperative mood, scope prefix (`feat(tf):`, `fix(bicep):`, `docs:`).
- Always include the trailer `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`.
- PR title mirrors the lead commit.
- PR body cross-links the issue (`Closes #N`) and notes which validation gates passed.
