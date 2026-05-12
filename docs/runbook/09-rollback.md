# Phase 09, rollback paths

## Goal

Document the reverse path at every phase so the operator knows the exact steps to abort.

## Decision tree

```text
What went wrong?

├─ Pre-cutover failure (Phases 01-06)
│   └─ Rollback: see per-phase Rollback section. No production impact.
│
├─ Cutover causing user-visible errors (Phase 07)
│   ├─ Pattern A (DNS flip)        -> reset CNAME to legacy
│   └─ Pattern B (weighted ramp)   -> set AGC endpoint weight to 0
│
└─ Post-decommission failure (Phase 08+)
    └─ Operationally hard. See "Worst case" below.
```

## Phase 07 rollback (production cutover)

### Option A: DNS flip back to ingress-nginx

```bash
LEGACY_LB_FQDN=$(az network public-ip show \
  -g MC_<rg>_<cluster>_<region> \
  -n kubernetes-<svc-uid> \
  --query dnsSettings.fqdn -o tsv)

az network dns record-set cname set-record \
  --resource-group <dns-rg> \
  --zone-name contoso.com \
  --record-set-name app \
  --cname "$LEGACY_LB_FQDN"
```

If you used the helper cmdlet for cutover, capture its rollback file:

```powershell
# Invoke-TrafficCutover writes a rollback plan to ./cutover-rollback-<timestamp>.json
Get-ChildItem ./cutover-rollback-*.json | Select-Object -Last 1
```

The JSON contains the prior CNAME and the exact `az network dns` command to reverse it.

### Option B: Weighted ramp rollback

```bash
az network traffic-manager endpoint update \
  --profile-name app-tm --resource-group <rg> \
  --name agc --type externalEndpoints --weight 0

az network traffic-manager endpoint update \
  --profile-name app-tm --resource-group <rg> \
  --name nginx --type externalEndpoints --weight 100
```

### Validation after rollback

```bash
dig +short app.contoso.com
curl -sS https://app.contoso.com/healthz
```

Confirm `nginx_ingress_controller_requests` rate climbs back and AGC `RequestCount` falls.

## Phase 08 rollback (post-decommission, worst case)

If you discover a critical issue **after** uninstalling ingress-nginx and DNS is on AGC:

1. **Stay on AGC.** Reverting to ingress-nginx is slower than fixing forward in almost every case.
2. Reapply the original Ingress YAMLs to a temporary namespace if you need to inspect annotation behaviour.
3. Reinstall ingress-nginx as a Helm release in `ingress-nginx` namespace **without** an `IngressClass` set as default. Apply original Ingress YAMLs with explicit `ingressClassName: nginx`.
4. Re-enable the previous `LoadBalancer` Service.
5. Switch DNS back per Phase 07 rollback.

This path takes 30-60 minutes. The fix-forward path is almost always shorter.

## Common pitfalls and recovery

| Symptom | Cause | Recovery |
|---|---|---|
| AGC frontend returns 502 for all requests | NetworkPolicy missing for AGC subnet | Re-apply `allow-from-agc` policies |
| AGC frontend returns 503 intermittently | HTTPRoute backendRef Service has no endpoints | `kubectl get endpoints -n <ns> <svc>`, fix Pod readiness |
| TLS handshake fails | `certificateRefs` Secret is in different namespace | Move Secret or use `ReferenceGrant` |
| Controller log: `AADSTS70021` | Federated credential subject mismatch | Verify exact `system:serviceaccount:<ns>:<sa>` value |
| Gateway stuck `Programmed: False` | AGC association subnet too small | Resize subnet or pick a larger one |
| Cutover spike in 5xx | Connection draining on legacy LB cut active streams | Lower DNS TTL further, retry next window |

## Version capture

Before any rollback, snapshot the current state for postmortem:

```bash
mkdir -p rollback-evidence/$(date +%Y%m%d-%H%M%S)
cd rollback-evidence/*

kubectl get gateway,httproute,backendtrafficpolicy,backendtlspolicy -A -o yaml > gateway-state.yaml
kubectl get pods -n azure-alb-system -o yaml > controller-state.yaml
kubectl logs -n azure-alb-system deployment/alb-controller --tail=2000 > controller.log
az network alb show -g <rg> -n <agc> > agc-show.json
az network alb frontend list -g <rg> --alb-name <agc> > agc-frontends.json
```

Attach to incident.

## Rollback

Phase 09 is the rollback procedure itself. There is no rollback for the rollback. If a rollback step fails midway, use `Version capture` (below) to document the state and escalate to Microsoft support with the snapshot evidence. Freeze the cluster state and wait for support guidance before proceeding.

## References

- [Helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) (accessed 2026-04-22)
- [Azure DNS CNAME](https://learn.microsoft.com/azure/dns/dns-getstarted-cli#create-a-dns-record-set-and-records) (accessed 2026-04-22)
- [Gateway API ReferenceGrant](https://gateway-api.sigs.k8s.io/api-types/referencegrant/) (accessed 2026-04-22)
