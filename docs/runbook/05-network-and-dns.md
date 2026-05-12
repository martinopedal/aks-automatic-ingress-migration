# Phase 05, network policies, DNS, and certs

## Goal

Align cluster network policies with the new AGC frontend, plan the DNS strategy for cutover, and migrate TLS certificate references from `Ingress.spec.tls` to Gateway listener `certificateRefs`.

## Prerequisites

- Phase 04 manifests generated and linted (not yet applied).
- DNS authority for the customer-facing hostnames.
- Cert source: Azure Key Vault, cert-manager, or pre-staged Kubernetes Secrets.

## Steps

### 1. Network policies

If the cluster runs network policies (Cilium on AKS Automatic by default), allow ingress to backend Services from the AGC subnet rather than from `ingress-nginx-controller` pod CIDR.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-agc
  namespace: <app-ns>
spec:
  podSelector:
    matchLabels:
      app: <app>
  policyTypes: [Ingress]
  ingress:
    - from:
        - ipBlock:
            cidr: 10.x.y.0/24
      ports:
        - protocol: TCP
          port: 8080
```

Keep the existing `allow-from-nginx` policy in place until Phase 08 to avoid blocking traffic during shadow / cutover.

### 2. Cluster egress (Azure Firewall allow-list)

AGC is a managed dataplane. The ALB controller in the cluster needs egress to:

- `*.management.azure.com` (ARM)
- `*.servicebus.windows.net` (controller telemetry)
- The Azure AD endpoints (`login.microsoftonline.com`, etc.)

If your hub Azure Firewall application rule collection blocks these, add an allow rule scoped to the AKS subnet.

### 3. DNS strategy

You have three viable patterns:

| Pattern | Pros | Cons |
|---|---|---|
| **A. Add new FQDN** (e.g., `app-agc.contoso.com`), validate in shadow, then DNS-flip the original `app.contoso.com` to AGC | Lowest risk, easy rollback | Two endpoints during transition |
| **B. Weighted DNS records** (Azure Traffic Manager weighted routing) | Gradual cutover, observable | Cache TTL effects, slower rollback |
| **C. Same hostname, both controllers attached** (impossible if both bind same Service IP, but valid for distinct frontends) | Simplest | DNS race conditions |

ALZ Corp default: **Pattern A**. Pattern B is acceptable for high-criticality apps where an instant cutover is unacceptable.

### 4. TLS certificates

For each TLS-bearing Ingress, decide cert source:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
spec:
  listeners:
    - name: https
      tls:
        certificateRefs:
          - kind: Secret
            name: app-tls
```

cert-manager has supported Gateway API since v1.12. Add the `--enable-gateway-api` flag and create `Certificate` resources that target the new `Gateway`. See [cert-manager Gateway API docs](https://cert-manager.io/docs/usage/gateway/) (accessed 2026-04-22).

For Azure Key Vault certs, mount via Secrets Store CSI driver and `secretObjects` to materialise as a Kubernetes Secret. The ALB controller does **not** read directly from Key Vault.

### 5. Health probes

If your Ingress used custom probe paths via `nginx.ingress.kubernetes.io/healthcheck-path`, translate to `HealthCheckPolicy`:

```yaml
apiVersion: alb.networking.azure.io/v1
kind: HealthCheckPolicy
metadata:
  name: app-health
  namespace: <app-ns>
spec:
  targetRef:
    group: ""
    kind: Service
    name: <service>
  default:
    interval: 5s
    timeout: 3s
    healthyThreshold: 1
    unhealthyThreshold: 3
    http:
      path: /healthz
      port: 8080
```

## Validation

- [ ] DNS records for the new endpoint (Pattern A) or weighted records (Pattern B) are created with **low TTL (60s)** to enable fast cutover and rollback.
- [ ] All `Gateway.listeners[].tls.certificateRefs` resolve to existing `Secrets` in the same namespace as the Gateway.
- [ ] NetworkPolicy `allow-from-agc` applied in every app namespace.
- [ ] Azure Firewall log shows no DENY entries from AKS subnet to AGC management endpoints.

## Rollback

This phase only adds DNS records and NetworkPolicies. To rollback:

- Delete added DNS records.
- `kubectl delete networkpolicy allow-from-agc -n <ns>`.
- TLS Secrets can stay; they are unused until the Gateway references them.

## References

- [cert-manager Gateway API support](https://cert-manager.io/docs/usage/gateway/) (accessed 2026-04-22)
- [Secrets Store CSI driver on AKS](https://learn.microsoft.com/azure/aks/csi-secrets-store-driver) (accessed 2026-04-22)
- [AGC HealthCheckPolicy spec](https://learn.microsoft.com/azure/application-gateway/for-containers/custom-health-probe) (accessed 2026-04-22)
