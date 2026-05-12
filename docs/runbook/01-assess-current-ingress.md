# Phase 01 — Assess current ingress estate

## Goal

Produce a complete inventory of every `Ingress` object in the cluster with each annotation classified as **portable**, **manual-fix**, or **blocker**. No resources are modified in this phase.

## Prerequisites

- Read access to every namespace in the cluster (`get,list` on `ingresses.networking.k8s.io`).
- `kubectl` configured with cluster context.
- `pwsh >= 7.4`.

## Steps

### 1. Capture the Ingress inventory

```bash
kubectl get ingress -A -o json > ingress-inventory.json
```

Verify count:

```bash
kubectl get ingress -A --no-headers | wc -l
```

### 2. Run the assessment cmdlet

The repo ships a PowerShell helper that classifies every annotation against the `ingress2gateway` translation matrix and ALZ Corp policy.

```powershell
Import-Module ./scripts/migration/module.psd1
Get-MigrationAssessment -InputPath ./ingress-inventory.json -OutputPath ./assessment.json
```

Output schema:

```json
{
  "totalIngresses": 12,
  "byClass": { "nginx": 10, "webapprouting.kubernetes.azure.com": 2 },
  "annotations": {
    "portable":    [ /* directly translated by ingress2gateway */ ],
    "manualFix":   [ /* needs HTTPRoute filter or BackendTrafficPolicy */ ],
    "blockers":    [ /* no AGC equivalent, redesign required */ ]
  },
  "tlsSecrets":   [ /* secrets referenced by Ingress.spec.tls */ ],
  "backendServices": [ /* unique Service refs */ ]
}
```

### 3. Triage blockers

Common blockers and recommended action:

| Annotation | Recommended action |
|---|---|
| `nginx.ingress.kubernetes.io/configuration-snippet` | Rewrite intent as `HTTPRoute` filter or `BackendTrafficPolicy`, or move logic to the application |
| `nginx.ingress.kubernetes.io/server-snippet` | As above |
| `nginx.ingress.kubernetes.io/auth-url` | Move to AGC `BackendTLSPolicy` + external auth, or use OIDC at AGC frontend |
| `nginx.ingress.kubernetes.io/canary*` | Use HTTPRoute weighted backendRefs (Gateway API native) |
| `nginx.ingress.kubernetes.io/rewrite-target` (regex) | Translate to HTTPRoute `URLRewrite` filter, validate edge cases |
| `nginx.ingress.kubernetes.io/proxy-body-size` | Set on `BackendTrafficPolicy.timeouts` or accept AGC default |

See [Ingress to Gateway API translation](https://gateway-api.sigs.k8s.io/guides/migrating-from-ingress/) (accessed 2026-04-22) and [AGC supported policies](https://learn.microsoft.com/azure/application-gateway/for-containers/api-specification-kubernetes) (accessed 2026-04-22).

### 4. Stakeholder review

Email or post the assessment to each app team that owns a blocker. Block on their decision before Phase 04.

## Validation

- [ ] `assessment.json` exists and lists every Ingress.
- [ ] Every annotation in the cluster appears in exactly one of the three buckets.
- [ ] App owners have acknowledged any `blockers` entries.

## Rollback

This phase is read-only. No rollback needed.

## References

- [`Get-MigrationAssessment` source](../../scripts/migration/Get-MigrationAssessment.ps1)
- [`ingress2gateway` annotation matrix](https://github.com/kubernetes-sigs/ingress2gateway/blob/main/pkg/i2gw/providers/ingressnginx/converter.go) (accessed 2026-04-22)
