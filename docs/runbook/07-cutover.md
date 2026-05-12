# Phase 07, production cutover

## Goal

Move production traffic from `ingress-nginx` (or the App Routing addon) to the AGC frontend. Choose between an instant DNS flip or a weighted ramp.

## Prerequisites

- Phase 06 shadow validation passed at thresholds for **at least 24 hours**.
- Change advisory board (CAB) approval if your org requires it.
- Communication sent to dependent teams.
- Rollback plan reviewed (Phase 09).

## Steps

### Option A: DNS flip (Pattern A from Phase 05)

This is the ALZ Corp default. Single CNAME swap, instant rollback.

#### 1. Lower TTL further (24 hours before cutover)

If TTL is currently 60s, leave it. If higher, lower it the day before:

```bash
az network dns record-set cname update \
  --resource-group <dns-rg> \
  --zone-name contoso.com \
  --name app \
  --set ttl=30
```

#### 2. Execute the flip

```bash
az network dns record-set cname set-record \
  --resource-group <dns-rg> \
  --zone-name contoso.com \
  --record-set-name app \
  --cname <agc-frontend-fqdn>
```

Or via the helper cmdlet, which validates both endpoints first:

```powershell
Import-Module ./scripts/migration/module.psd1

Invoke-TrafficCutover `
  -LegacyEndpoint https://app.contoso.com `
  -NewEndpoint https://app-agc.contoso.com `
  -DnsZoneResourceGroup <dns-rg> `
  -DnsZoneName contoso.com `
  -RecordSetName app `
  -TargetCname <agc-frontend-fqdn>
```

#### 3. Watch dashboards

- AGC association metric: `RequestCount` should ramp from low (shadow) to legacy levels within ~1-2 minutes (resolver TTL plus client cache).
- `ingress-nginx-controller` metric: `nginx_ingress_controller_requests` should fall toward 0.
- App-level error rate: should remain flat.

### Option B: Weighted ramp (Pattern B from Phase 05)

Use Azure Traffic Manager Weighted profile. Pre-create endpoints for both legacy and AGC.

```bash
# Ramp 5% to AGC
az network traffic-manager endpoint update \
  --profile-name app-tm --resource-group <rg> \
  --name agc --type externalEndpoints --weight 5

az network traffic-manager endpoint update \
  --profile-name app-tm --resource-group <rg> \
  --name nginx --type externalEndpoints --weight 95

# Wait 30 minutes, observe, then bump to 25%, 50%, 100%
```

The helper cmdlet supports ramp:

```powershell
Invoke-TrafficCutover `
  -LegacyEndpoint https://app.contoso.com `
  -NewEndpoint https://app-agc.contoso.com `
  -RampPercent 5 `
  -TrafficManagerProfile app-tm `
  -TrafficManagerResourceGroup <rg>
```

Repeat with `-RampPercent 25`, `50`, `100` over the cutover window.

### 3. Soak

After 100% on AGC, soak for **at least 7 days** before Phase 08. Do not decommission ingress-nginx during the soak; it must remain available for fast rollback.

## Validation

- [ ] Hostname resolves to AGC frontend (`dig +short app.contoso.com`).
- [ ] AGC association `RequestCount` matches historical baseline.
- [ ] `nginx_ingress_controller_requests` rate is at or near zero.
- [ ] No spike in 5xx, latency p95, or cert errors during ramp.
- [ ] On-call team has acknowledged the cutover and knows the rollback command.

## Rollback

See [Phase 09](./09-rollback.md). For Option A, the rollback is a single `az network dns record-set cname set-record` back to the original target. For Option B, set the AGC endpoint weight back to 0.

## References

- [Azure DNS record TTL](https://learn.microsoft.com/azure/dns/dns-zones-records) (accessed 2026-04-22)
- [Azure Traffic Manager weighted routing](https://learn.microsoft.com/azure/traffic-manager/traffic-manager-routing-methods#weighted) (accessed 2026-04-22)
