# Threat Model, AGC Migration Path

**Owner:** Sentinel  
**Last reviewed:** 2026-04-22

## Scope

This threat model covers the ingress path for workloads migrated from `ingress-nginx` or App Routing addon to Gateway API with Application Gateway for Containers (AGC).

Default assumptions for this repository:

- ALZ Corp hub-spoke network.
- Central Azure Firewall controls egress.
- AKS cluster API is private.
- No public IPs on AKS nodes.
- AGC uses managed identity with Workload Identity, not service principal secrets.

Reference architecture and AGC platform docs:

- [AKS landing zone accelerator](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/aks/landing-zone-accelerator)
- [Application Gateway for Containers overview](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview)

## Trust boundaries and public surface

Primary boundaries:

1. Internet or enterprise clients to AGC frontend.
2. AGC dataplane to backend Kubernetes services.
3. AKS workloads to external dependencies through hub firewall.
4. Control plane identities to Azure Resource Manager.

Public surface we defend:

- AGC frontend listeners (HTTP and HTTPS) exposed by Gateway resources.
- DNS records that resolve application hostnames to AGC frontend addresses.
- Any management endpoint that is reachable from outside trusted admin networks.

Baseline controls:

- Only expose listeners and hostnames that are explicitly required by workload routes.
- Prefer HTTPS listeners. Use HTTP only for redirect to HTTPS.
- Keep admin and management access on private paths only.
- Use WAF where threat profile requires L7 protections.

References:

- [AGC components and data path](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/application-gateway-for-containers-components)
- [Gateway API HTTP routing model](https://gateway-api.sigs.k8s.io/concepts/api-overview/)

## NSG and firewall posture

### NSG rules

- Deny inbound by default on AKS and AGC subnets.
- Allow only required inbound to AGC frontend data path.
- Restrict east-west traffic between subnets to required ports and protocols.
- Deny direct inbound from AGC subnet to backend nodes except required service traffic.

### Azure Firewall rules

- Default deny egress from workload subnets.
- Allowlist required FQDNs and service tags for:
  - AKS platform dependencies.
  - Azure Container Registry and image sources.
  - Identity, telemetry, and policy endpoints required by the platform.
- Log and review denied flows during migration dry runs before cutover.

References:

- [Azure Firewall in hub-spoke networks](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/firewalls/azure-firewall)
- [AKS egress outbound controls](https://learn.microsoft.com/en-us/azure/aks/limit-egress-traffic)

## mTLS posture

Target posture for migrated applications:

1. **Client to edge:** TLS 1.2+ on AGC listeners with managed certificates and strict hostname routing.
2. **Edge to backend:** Re-encrypt traffic to backend services. Prefer mutual TLS for sensitive services.
3. **Service-to-service:** Use in-cluster identity-aware controls. If controller features are insufficient for workload requirements, use service mesh or application-layer mTLS.

Implementation notes:

- Gateway API defines TLS behavior for listener termination and upstream TLS policy attachment.
- Not every mTLS pattern is supported uniformly by every controller version. Validate controller behavior in staging before production cutover.

References:

- [Gateway API TLS concepts](https://gateway-api.sigs.k8s.io/guides/tls/)
- [Gateway API BackendTLSPolicy](https://gateway-api.sigs.k8s.io/api-types/backendtlspolicy/)

## Key risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Overexposed AGC listeners or wildcard host rules | Unintended external access | Limit listeners and hostnames to approved routes. Review Gateway and HTTPRoute objects in PR before apply. |
| Broad NSG allow rules during migration | Lateral movement and bypass of segmentation | Use explicit allow rules with source and destination scoping. Remove temporary rules after cutover validation. |
| Firewall allowlists incomplete | Outage during cutover | Run migration in dry-run phases. Use firewall logs to build and validate allowlists before switching traffic. |
| No backend TLS or weak cert validation | MITM risk on internal path | Enforce backend TLS policies and certificate verification for sensitive services. |
| Controller feature mismatch for mTLS expectations | Security gap versus design intent | Verify capabilities for current AGC and Gateway API versions in staging. Track exceptions in runbook and risk register. |

## Minimum review checklist per migration wave

- [ ] External hostnames and listener ports are explicitly approved.
- [ ] NSG inbound and east-west rules follow least privilege.
- [ ] Azure Firewall egress rules are allowlist-based and logged.
- [ ] TLS certificates and rotation process are documented.
- [ ] mTLS requirements are mapped per application tier, including exceptions.
- [ ] Security sign-off recorded before production cutover.
