# AGENTS.md: aks-automatic-ingress-migration

Read this first. Then read `.github/copilot-instructions.md` and `.squad/team.md`.

## Mission

Help AKS Automatic users migrate off `ingress-nginx` / App Routing addon to Gateway API + Application Gateway for Containers before Nov 2026.

## Project conventions

- **No em dashes.** Use periods or commas.
- **Read-only first.** Any tool, script, or example must default to dry-run / plan / what-if.
- **Bicep + Terraform parity.** Every infra example ships in both. Tests verify outputs match.
- **ALZ Corp by default.** Examples assume hub-spoke with central Azure Firewall egress, no public IPs on AKS, private cluster API.
- **Citations required.** Every claim about retirement dates, default behavior, or gotchas links to MS docs or GH releases.

## Squad workflow

1. Issues labeled `squad` go to **Lead** for triage.
2. Lead adds a `squad:{member}` label and a triage comment.
3. The named member picks up the issue in their next session.
4. PRs require at least one non-author reviewer and clean CI.

## Agent quick reference

| Domain | Owner |
|---|---|
| Terraform / Bicep for AGC and AKS | Forge |
| Kubernetes manifests, Gateway API translation, Helm | Atlas |
| Identity & RBAC (workload identity, AGC managed identity) | Iris |
| Security review (network policies, pod security, supply chain) | Sentinel |
| Migration runbook, breaking-change tracking, MS doc cross-refs | Sage |
| Triage, design, PR sign-off | Lead |

## Validation gates before merge

```powershell
terraform fmt -check -recursive
terraform validate
# Bicep
az bicep build --file <file>
# Manifests
helm lint charts/*
kubectl --dry-run=client apply -f manifests/
```

## Related

- [.github/copilot-instructions.md](.github/copilot-instructions.md)
- [.squad/team.md](.squad/team.md)
- [.squad/routing.md](.squad/routing.md)
