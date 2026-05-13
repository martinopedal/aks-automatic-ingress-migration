# AksAgcMigration PowerShell Module

PowerShell module for migrating AKS Automatic clusters from ingress-nginx to Gateway API with Application Gateway for Containers (AGC).

## Prerequisites

- PowerShell 7.0 or later
- kubectl on PATH, configured for your cluster
- ingress2gateway binary (for Convert-IngressToGateway)

### Install ingress2gateway

```shell
# Pin to GA baseline (v1.0.0, released 2026-03-20):
go install sigs.k8s.io/ingress2gateway@v1.0.0
# Or use the latest (v1.1.0 as of 2026-04):
go install sigs.k8s.io/ingress2gateway@latest
```

Or download from https://github.com/kubernetes-sigs/ingress2gateway/releases (v1.0.0 GA tag: <https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.0.0>; v1.1.0 latest: <https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.1.0>).

## Usage

### Import Module

```powershell
Import-Module ./scripts/migration/module.psd1
```

### Convert-IngressToGateway

Translates Ingress YAML to Gateway API HTTPRoute YAML.

```powershell
# Preview translation
Convert-IngressToGateway -InputPath ./ingress.yaml -OutputPath ./gateway -WhatIf

# Translate without confirmation
Convert-IngressToGateway -InputPath ./manifests -OutputPath ./gateway -Force
```

### Get-MigrationAssessment

Read-only cluster inventory.

```powershell
# Markdown report
Get-MigrationAssessment

# JSON output
Get-MigrationAssessment -OutputFormat json | Out-File assessment.json
```

### Invoke-TrafficCutover

Generates a human-driven traffic cutover checklist.

```powershell
# Preview mode (default)
Invoke-TrafficCutover -FromGatewayClassName nginx -Namespace myapp

# Actionable checklist (still read-only)
Invoke-TrafficCutover -FromGatewayClassName nginx -Namespace prod -DryRun:$false
```

## Testing

Run Pester v5 tests:

```powershell
Invoke-Pester ./scripts/migration/tests
```

Exclude integration tests (require ingress2gateway binary):

```powershell
Invoke-Pester ./scripts/migration/tests -ExcludeTag integration
```

## Design philosophy

All cmdlets default to dry-run or preview. `Convert-IngressToGateway` requires `-WhatIf:$false` or `-Force` to actually write files. `Get-MigrationAssessment` is read-only by design. `Invoke-TrafficCutover` produces a Markdown checklist; the actual DNS or Traffic Manager change stays a human decision because cutover failure modes (cache TTL, partial propagation, routing loops) need eyes on dashboards, not a script.

Each script does one thing. Translation, inventory, and cutover are separate cmdlets so a failure in one does not contaminate the others.

## Links

- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [Application Gateway for Containers](https://learn.microsoft.com/azure/application-gateway/for-containers/)
- [ingress2gateway Tool](https://github.com/kubernetes-sigs/ingress2gateway)
