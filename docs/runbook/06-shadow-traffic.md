# Phase 06, shadow traffic and observation

## Goal

Apply the generated `Gateway` and `HTTPRoute` manifests to the cluster, point synthetic and real-but-low-stakes traffic at the new AGC frontend, and observe for parity with the legacy `ingress-nginx` path. **No production cutover yet.**

## Prerequisites

- Phase 04 manifests generated.
- Phase 05 NetworkPolicies and TLS Secrets in place.
- New DNS records (Pattern A) or weighted records (Pattern B) created.
- Observability stack collecting AGC metrics (Azure Monitor for Containers, or Prometheus scraping the controller).

## Steps

### 1. Apply manifests in dependency order

```bash
kubectl apply -f gateways/<gateway-namespace>/gateway.yaml

kubectl wait --for=condition=Programmed gateway/<name> \
  -n <gateway-namespace> --timeout=180s

kubectl apply -R -f gateways/
```

### 2. Verify Gateway is healthy

```bash
kubectl get gateway -A -o wide
kubectl describe gateway <name> -n <gateway-namespace>
```

Look for:

```text
Conditions:
  Type: Accepted          Status: True
  Type: Programmed        Status: True
Listeners:
  - Name: https
    Conditions:
      Accepted: True
      ResolvedRefs: True
```

### 3. Smoke test from a pod inside the cluster

```bash
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl -sS -H "Host: app.contoso.com" https://<agc-frontend-fqdn>/healthz
```

### 4. Smoke test from on-prem or jumpbox

```bash
curl -sS https://app-agc.contoso.com/healthz
```

If using `azure-alb-internal`, this requires connectivity from a peered VNet, ExpressRoute, or VPN.

### 5. Synthetic shadow traffic

Run the smoke workflow committed at `.github/workflows/smoke-test.yml` against the new endpoint:

```bash
gh workflow run smoke-test.yml \
  -f endpoint=https://app-agc.contoso.com \
  -f duration=300
```

The workflow captures p50/p95/p99 latency and error rate.

### 6. Compare with legacy

Pull the same metrics window for the existing `ingress-nginx` endpoint. Acceptance criteria:

| Metric | Threshold |
|---|---|
| 5xx rate | within +0.1% of legacy |
| p95 latency | within +20ms of legacy |
| Connection errors | 0 |
| Cert handshake errors | 0 |

If any threshold fails, do not proceed to Phase 07. Iterate on Phase 04 / 05 fixes.

### 7. Run the migration helper preflight

```powershell
Import-Module ./scripts/migration/module.psd1

Invoke-TrafficCutover -DryRun `
  -LegacyEndpoint https://app.contoso.com `
  -NewEndpoint https://app-agc.contoso.com `
  -RampPercent 0
```

The cmdlet probes both endpoints and refuses to print a real cutover plan if shadow parity is not met.

## Validation

- [ ] All Gateways report `Programmed: True`.
- [ ] All HTTPRoutes report `Accepted: True` and `ResolvedRefs: True`.
- [ ] Shadow smoke-test workflow run is green for at least **24 hours**.
- [ ] Comparison metrics are within thresholds.
- [ ] No new alerts in Azure Monitor for the AGC association resource.

## Rollback

```bash
kubectl delete -R -f gateways/
```

This removes the AGC routing without touching the legacy `ingress-nginx` path. Production traffic is unaffected because no DNS flip has happened.

## References

- [AGC observability](https://learn.microsoft.com/azure/application-gateway/for-containers/monitor-application-gateway-for-containers) (accessed 2026-04-22)
- [Gateway API status conditions](https://gateway-api.sigs.k8s.io/concepts/conformance/) (accessed 2026-04-22)
