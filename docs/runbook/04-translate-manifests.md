# Phase 04 — Translate Ingress manifests to Gateway + HTTPRoute

## Goal

Generate `Gateway`, `HTTPRoute`, and supporting policy manifests from the existing `Ingress` inventory using `ingress2gateway`, then patch the gaps that the tool cannot translate.

## Prerequisites

- Phase 01 assessment complete (`assessment.json` on disk).
- Phase 02 AGC provisioned, controller healthy with identity.
- `ingress2gateway >= 0.3.0` on PATH.
- A `gateways/` working directory.

## Steps

### 1. Run the bulk converter

The `Convert-IngressToGateway` cmdlet wraps `ingress2gateway` with the AGC GatewayClass and emits per-namespace files.

```powershell
Import-Module ./scripts/migration/module.psd1

Convert-IngressToGateway `
  -InputPath ./ingress-inventory.json `
  -OutputDirectory ./gateways `
  -GatewayClassName "azure-alb-external" `
  -ListenerProtocol "HTTPS" `
  -DryRun
```

Output structure:

```text
gateways/
  <namespace>/
    gateway.yaml
    httproute-<ingress-name>.yaml
  unsupported.md   # human-readable list of skipped annotations
```

Re-run without `-DryRun` to actually write files.

### 2. Choose your Gateway topology

Decide before Phase 06 which topology you want. AGC supports both:

| Topology | When to use |
|---|---|
| **Shared Gateway** per cluster (one `Gateway` in a platform namespace, app teams attach `HTTPRoute` via `parentRefs`) | Cost-optimised, central frontend cert mgmt, ALZ Corp default |
| **Gateway per namespace** | Strong tenant isolation, multi-tenant clusters with hard boundaries |

For ALZ Corp, prefer shared. The hello-world sample uses shared.

### 3. Internal vs external frontend

Set the GatewayClass and `infrastructure.annotations` to control public exposure:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gw-internal
  namespace: gateway-system
spec:
  gatewayClassName: azure-alb-internal
  listeners:
    - name: https
      port: 443
      protocol: HTTPS
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: tls-cert
```

Default for ALZ Corp is **`azure-alb-internal`** (no public IP).

### 4. Patch unsupported annotations

For each entry in `unsupported.md`, apply one of the patterns from [Phase 01 triage](./01-assess-current-ingress.md#3-triage-blockers). Common patterns:

- **Canary / weighted traffic**: convert to `HTTPRoute.spec.rules[].backendRefs[].weight`.
- **Header rewrite**: add `HTTPRoute.spec.rules[].filters[]` of type `RequestHeaderModifier`.
- **Path rewrite**: add `URLRewrite` filter.
- **Body size limit**: create a `BackendTrafficPolicy` per AGC docs.
- **mTLS to backend**: create a `BackendTLSPolicy` referring to a `ConfigMap` with the CA bundle.

### 5. Lint the generated manifests

```bash
kubectl apply --dry-run=client -f gateways/ -R
```

For static schema validation:

```bash
kubeconform -strict -kubernetes-version 1.30.0 \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  $(find gateways -name '*.yaml')
```

## Validation

- [ ] Every `Ingress` from the inventory has a corresponding `HTTPRoute` (or is documented as intentionally dropped in `unsupported.md`).
- [ ] `kubectl apply --dry-run=client` exits 0.
- [ ] `kubeconform` exits 0.
- [ ] No `HTTPRoute` references a backend `Service` that does not exist (use the `backendServices` list from Phase 01 to cross-check).

## Rollback

The generated files are in `./gateways/` and not yet applied to the cluster. To rollback, delete the directory.

```powershell
Remove-Item -Recurse -Force ./gateways
```

## References

- [`ingress2gateway` README](https://github.com/kubernetes-sigs/ingress2gateway) (accessed 2026-04-22)
- [Gateway API HTTPRoute spec](https://gateway-api.sigs.k8s.io/api-types/httproute/) (accessed 2026-04-22)
- [AGC API spec for Kubernetes (BackendTrafficPolicy, BackendTLSPolicy, HealthCheckPolicy)](https://learn.microsoft.com/azure/application-gateway/for-containers/api-specification-kubernetes) (accessed 2026-04-22)
