# Kubernetes manifests and translation catalog

*Not an official Microsoft product. Community migration toolkit. See LICENSE.*

Gateway API manifests, Ingress-to-Gateway translation patterns, and sample workloads for AKS Automatic with Application Gateway for Containers.

## Structure

```
manifests/
├── ingress-to-gateway/  # Translation catalog: Ingress → Gateway API side-by-side
│   ├── tls.yaml         # TLS termination
│   ├── path-rewrite.yaml
│   ├── header-rewrite.yaml
│   └── weighted-traffic.yaml
```

## How to use this directory

**If you are migrating from ingress-nginx or App Routing addon:**

1. Read `docs/runbook/04-translate-manifests.md` for the canonical translation workflow.
2. Use `ingress2gateway` for bulk conversion (`scripts/migration/Convert-IngressToGateway.ps1` wraps the tool).
3. Consult `manifests/ingress-to-gateway/` for patterns the automated tool cannot handle (annotations, rewrites, edge cases).

**If you are starting fresh with Gateway API:**

1. Review `examples/quickstart/` for a minimal smoke test (HTTP only, single backend).
2. Reference `examples/hello-world/` for ALZ Corp defaults (Workload Identity, private Gateway, hub-spoke).

## Ingress annotation to Gateway API translation

The `manifests/ingress-to-gateway/` catalog maps common ingress-nginx annotations to Gateway API equivalents. Each file shows the before (Ingress) and after (Gateway + HTTPRoute) side-by-side.

For comprehensive coverage, read `docs/runbook/04-translate-manifests.md`.

## Validation

CI validates all manifests with kubeconform and helm lint (`.github/workflows/validate.yml`). Local validation:

```bash
# Syntax check (no cluster required)
kubectl apply --dry-run=client -f manifests/<file>.yaml

# Full validation (requires cluster with Gateway API CRDs)
kubectl apply --dry-run=server -f manifests/<file>.yaml
```

## References

- Gateway API specification: https://gateway-api.sigs.k8s.io/
- AGC documentation: https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/
- ingress2gateway: https://github.com/kubernetes-sigs/ingress2gateway
- Migration runbook: `docs/runbook/04-translate-manifests.md`
