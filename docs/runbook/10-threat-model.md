# Threat Model, AGC Migration Path

**Owner:** Sentinel  
**Last reviewed:** 2026-05-13

## Scope

This threat model covers the ingress path for workloads migrated from `ingress-nginx` or App Routing addon to Gateway API with Application Gateway for Containers (AGC).

Default assumptions for this repository:

- ALZ Corp hub-spoke network.
- Central Azure Firewall controls egress.
- AKS cluster API is private.
- No public IPs on AKS nodes.
- AGC uses managed identity with Workload Identity, not service principal secrets.

Reference architecture and AGC platform docs:

- [AKS landing zone accelerator](https://learn.microsoft.com/azure/cloud-adoption-framework/scenarios/app-platform/aks/landing-zone-accelerator)
- [Application Gateway for Containers overview](https://learn.microsoft.com/azure/application-gateway/for-containers/overview)

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

- [AGC components and data path](https://learn.microsoft.com/azure/application-gateway/for-containers/application-gateway-for-containers-components)
- [Gateway API HTTP routing model](https://gateway-api.sigs.k8s.io/concepts/api-overview/)

## AKS Automatic considerations

AKS Automatic clusters cannot install the ALB Controller via Helm. Per the [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq), "Helm deployments of the ALB Controller aren't supported with AKS Automatic." The only supported AGC controller path on Automatic is the AKS add-on (currently preview), which auto-creates a managed identity named `applicationloadbalancer-<cluster-name>` in the node resource group `MC_<rg>_<cluster>_<region>` per the [AGC ALB Controller AKS add-on quickstart](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon).

Security implications:

- The auto-created identity sits in a Microsoft-managed resource group. It is outside the customer's normal subscription RBAC scope and harder to govern through ALZ Corp policies that target the workload resource group.
- Customer cannot choose the identity name, the subnet name (`aks-appgateway`), or the role assignment scope. The add-on applies a fixed configuration per the add-on quickstart.
- This toolkit treats the add-on path as a documented alternative, not a recommended default for production. Rationale and tradeoffs are in [ADR-004](../adr/ADR-004-toolkit-posture-on-preview-features.md).

Track the auto-created identity in your RBAC inventory by its principalId, not by its resource group. The principalId persists across `MC_` resource group recreations.

## Threat catalog by trust boundary

STRIDE-style enumeration for the four boundaries listed above. Each row pairs a concrete threat scenario with a specific mitigation and citation.

### Boundary 1: Internet or enterprise clients to AGC frontend

| STRIDE | Threat scenario | Mitigation |
|---|---|---|
| Spoofing | Client sends a forged Host header to claim a hostname owned by another team's HTTPRoute. | Bind hostnames to specific listeners and restrict route attachment via `allowedRoutes.namespaces.selector` per the [Gateway API security model](https://gateway-api.sigs.k8s.io/concepts/security/). |
| Tampering | TLS downgrade attempt to weaken in-flight encryption. | AGC enforces TLS 1.2 minimum; SSL 2.0, 3.0, TLS 1.0, and TLS 1.1 are disabled and not configurable per the [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq). |
| Repudiation | Client denies sending a damaging request. | Enable AGC access logs to a Log Analytics workspace and retain per audit policy. See [AGC monitoring](https://learn.microsoft.com/azure/application-gateway/for-containers/monitor-application-gateway-for-containers). |
| Info disclosure | Server cert misissued or shared across tenants exposes private key material. | Use unique managed certificates per hostname; rotate per documented process. AGC supports BYO certs via Key Vault per the [AGC components overview](https://learn.microsoft.com/azure/application-gateway/for-containers/application-gateway-for-containers-components). |
| Denial of service | L7 flood saturating frontend listener. | Apply WAF policy on the AGC frontend with rate-limit rules. WAF availability per the [AGC overview](https://learn.microsoft.com/azure/application-gateway/for-containers/overview). |
| Elevation of privilege | Compromise of AGC dataplane is used to reach the AKS control plane. | AGC dataplane has no path to AKS control plane identity. The AGC managed identity is scoped to its own resource group, not the cluster, per the AGC quickstart role assignments. |

### Boundary 2: AGC dataplane to backend Kubernetes services

| STRIDE | Threat scenario | Mitigation |
|---|---|---|
| Spoofing | A pod with a matching label selector is impersonated by a malicious pod scheduled in the same namespace. | Restrict pod creation in routed namespaces with Kubernetes RBAC; verify backend identity with [BackendTLSPolicy](https://gateway-api.sigs.k8s.io/api-types/backendtlspolicy/) where the workload supports TLS. |
| Tampering | MITM between the AGC subnet and pod CIDR alters request payload on the cluster network. | Re-encrypt to backends with end-to-end TLS, supported per the [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq). |
| Repudiation | Backend log shows the request but not which client originated it. | Forward client IP via `X-Forwarded-For`; log at the workload. AGC preserves client IP per the [AGC components data path](https://learn.microsoft.com/azure/application-gateway/for-containers/application-gateway-for-containers-components). |
| Info disclosure | Plaintext HTTP between AGC and backend leaks request bodies on the cluster network. | Configure backend listeners on TLS only and reject plaintext at the workload. Pair with BackendTLSPolicy for cert verification. |
| Denial of service | High request volume from AGC overwhelms a single pod replica. | Use HPA on workloads; AGC frontend probes drain unhealthy backends per the AGC components doc. |
| Elevation of privilege | Compromised backend pod uses egress to reach the AKS control plane or other workloads. | Apply default-deny egress NetworkPolicy and add explicit allow rules per [AKS network policies](https://learn.microsoft.com/azure/aks/use-network-policies). |

### Boundary 3: AKS workloads to external dependencies through hub firewall

| STRIDE | Threat scenario | Mitigation |
|---|---|---|
| Spoofing | DNS poisoning redirects egress to an attacker-controlled host. | Route DNS through Azure Firewall DNS proxy with Azure-provided DNS upstream per [AKS egress traffic](https://learn.microsoft.com/azure/aks/limit-egress-traffic). |
| Tampering | Untrusted upstream proxy injects responses. | Enforce TLS for all egress; pin certificates for sensitive APIs at the workload. |
| Repudiation | Workload denies making a specific egress call. | Enable Azure Firewall logs; correlate flows with pod identity via Workload Identity tokens per [Workload Identity overview](https://learn.microsoft.com/azure/aks/workload-identity-overview). |
| Info disclosure | Workload exfiltrates data to an unsanctioned FQDN. | Default-deny egress on Azure Firewall; allowlist required FQDNs and service tags only, per [AKS egress traffic](https://learn.microsoft.com/azure/aks/limit-egress-traffic). |
| Denial of service | Workload exhausts firewall SNAT ports. | Monitor SNAT port utilization; provision additional public IPs on the firewall. |
| Elevation of privilege | Stolen IMDS token used to call ARM beyond pod scope. | Disable IMDS access for pods that use Workload Identity; rely on federated token exchange per the Workload Identity overview. |

### Boundary 4: Control plane identities to Azure Resource Manager

| STRIDE | Threat scenario | Mitigation |
|---|---|---|
| Spoofing | Forged OIDC token presented to AAD. | Workload Identity validates tokens against the AKS OIDC issuer; the federated credential subject must match the requesting ServiceAccount per [Workload Identity overview](https://learn.microsoft.com/azure/aks/workload-identity-overview). |
| Tampering | Role assignment edited to grant Owner where Reader was intended. | Manage role assignments through PIM with approvals; review via Azure RBAC change logs. |
| Repudiation | Identity denies performing a destructive ARM call. | ARM activity logs capture caller principalId for every write. Retain in Log Analytics. |
| Info disclosure | Over-scoped identity reads resources outside the AGC scope. | Scope ALB Controller identity to the `AppGwForContainersConfigurationManager` role on the ApplicationLoadBalancer resource per the [AGC quickstart](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller). |
| Denial of service | Misbehaving controller throttles ARM for the entire subscription. | ARM throttles per principal; monitor 429 responses with Azure Monitor and back off in-controller. |
| Elevation of privilege | ALB Controller identity granted Contributor at resource group scope instead of the documented role. | Apply only the role assignments listed in the AGC quickstart. The add-on applies a fixed minimum set; the Helm path requires customer discipline. |

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

- [Azure Firewall in hub-spoke networks](https://learn.microsoft.com/azure/architecture/example-scenario/firewalls/azure-firewall)
- [AKS egress outbound controls](https://learn.microsoft.com/azure/aks/limit-egress-traffic)

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

## ALB Controller identity and RBAC

The ALB Controller is the in-cluster operator that translates Gateway and HTTPRoute resources into AGC configuration via ARM. Two install paths exist, and the security boundary differs between them.

**Helm install (standard AKS):** The customer creates the managed identity in a customer-controlled resource group, federates it to the controller's ServiceAccount, and assigns the `AppGwForContainersConfigurationManager` role at the ApplicationLoadBalancer scope. Identity name, subnet name, and RBAC scope are explicit and auditable. See the [Helm install quickstart](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller).

**AKS add-on (preview, required on AKS Automatic):** The add-on auto-creates a managed identity named `applicationloadbalancer-<cluster-name>` in the node resource group `MC_<rg>_<cluster>_<region>`, federates it, and assigns the role. Customer cannot choose any of these names. See [ADR-004](../adr/ADR-004-toolkit-posture-on-preview-features.md) for the toolkit's posture and the [add-on quickstart](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon) for the auto-created resources.

Per the [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq), each ALB Controller must use its own unique managed identity. Sharing one identity across multiple controllers is unsupported.

### ApplicationLoadBalancer CR trust model

The `ApplicationLoadBalancer` custom resource (group `alb.networking.azure.io`) tells the controller which AGC resource to manage. Anyone with `create` on this CR can ask the controller to attach to a frontend in the customer's subscription. The controller then acts on the CR using its own managed identity. Lock down via Kubernetes RBAC:

- Restrict `create`, `update`, `delete` on `applicationloadbalancers.alb.networking.azure.io` to a small platform team.
- Audit all changes via kube-audit (see Logging and detection).
- Do not grant these verbs to workload service accounts or developer namespaces.

### Blast radius if the ALB Controller ServiceAccount token leaks

The controller ServiceAccount token is a JWT that the controller exchanges for an AAD token via the federated identity credential. If a pod outside the controller can read the token (for example via a misconfigured `automountServiceAccountToken: true` plus a host-path mount), the attacker can:

- Mint AAD tokens for the controller's federated identity until the credential is revoked.
- Use those tokens to call ARM scoped to the role assignment on the ApplicationLoadBalancer resource. With the documented `AppGwForContainersConfigurationManager` role this means modifying AGC configuration (frontends, routes, backend pools), not subscription-wide changes.
- The blast radius is bounded by the role assignment scope. Granting Contributor at resource group scope (instead of the documented minimum) widens this significantly. Stay on the role assignments listed in the AGC quickstart.

Mitigations:

- Restrict pod-to-pod traffic in the `azure-alb-system` namespace via NetworkPolicy.
- Set `automountServiceAccountToken: false` on every ServiceAccount that does not need a token, per [AKS pod security guidance](https://learn.microsoft.com/azure/aks/use-pod-security-on-azure-policy).
- Rotate the federated credential if compromise is suspected; revocation is immediate.

## Gateway API route attachment controls

A Gateway listener controls which HTTPRoutes can attach to it via `allowedRoutes.namespaces.from`. The values are:

- `Same`: only routes in the same namespace as the Gateway can attach. This is the default per the Gateway API spec.
- `Selector`: routes from namespaces matching a label selector can attach.
- `All`: any namespace in the cluster can attach a route.

Per the [Gateway API security model](https://gateway-api.sigs.k8s.io/concepts/security/), `from: All` is documented as an insecure configuration in the canonical example. For a shared platform Gateway, set `from: Selector` and match on `kubernetes.io/metadata.name` for an explicit list of allowed namespaces.

### Why label-based selection is safer than free-for-all

If a Gateway exposes hostname `api.contoso.com` and `allowedRoutes.namespaces.from: All` is set, any namespace owner can create an HTTPRoute claiming a path on that host. The Gateway API security model documents the hostname conflict resolution as first-come-first-served on `creationTimestamp`. A workload namespace can therefore attach to a Gateway it should not own, intercept a path, and serve responses for it.

The mitigation is two-layer:

1. Set `allowedRoutes.namespaces.from: Selector` on the Gateway, listing only the namespaces that own routes for that hostname.
2. Use only `kubernetes.io/metadata.name` as the selector key. Per the security model, custom labels can be modified by anyone with `update` on namespaces, which moves the trust decision off the Gateway owner.

For cross-namespace backend references (HTTPRoute in namespace A, Service in namespace B), the destination namespace must publish a `ReferenceGrant` allowing the reference. There is no implicit cross-namespace trust per the [Gateway API security model](https://gateway-api.sigs.k8s.io/concepts/security/).

## Supply chain

### ALB Controller image

The ALB Controller image is published to Microsoft Container Registry under `mcr.microsoft.com/application-lb/images/alb-controller`. Pin to a specific version, never `latest`. The pinned version becomes part of the toolkit's verified configuration. See the [ALB Controller release notes](https://learn.microsoft.com/azure/application-gateway/for-containers/alb-controller-release-notes) for available versions and the changelog per release.

### Helm chart

The Helm chart is an OCI artifact at `oci://mcr.microsoft.com/application-lb/charts/alb-controller`. The same versioning rule applies: pin to a specific chart version aligned with the controller image version. Document the pinned versions in IaC values files so that drift between environments is visible in git history.

For pulls from MCR no auth is required for the public artifact. If your environment proxies MCR through a private registry, mirror the artifact and pin to the digest, not the tag, to detect tag-mutation tampering.

### AKS add-on path

The add-on is Microsoft-managed. Customers cannot pin the controller version, the chart version, or the image digest. The version follows the AKS release channel for the cluster. Per [ADR-004](../adr/ADR-004-toolkit-posture-on-preview-features.md), the toolkit treats this as a documented alternative; supply chain pinning is not available on this path.

If supply chain reproducibility is a requirement (regulated industries, air-gapped environments), use the Helm install path and pin both image and chart to digests.

## Logging and detection

| Source | What it captures | What to alert on |
|---|---|---|
| AGC access logs | Per-request: timestamp, client IP, host, path, status, latency. Configured via diagnostic settings per [AGC monitoring](https://learn.microsoft.com/azure/application-gateway/for-containers/monitor-application-gateway-for-containers). | 5xx rate spike on a single hostname, unexpected client IP geographies, sudden change in request rate per route. |
| AKS kube-audit | API server requests: who, what verb, what resource, success or denial. Enabled via [AKS resource logs](https://learn.microsoft.com/azure/aks/monitor-aks). | `create` or `update` on `httproutes.gateway.networking.k8s.io` or `applicationloadbalancers.alb.networking.azure.io` from unexpected service accounts; failed RBAC checks against Gateway API resources. |
| AKS kube-controller-manager | Reconciliation actions, leader election, errors. | Sustained reconciliation errors on Gateway resources, leader election flapping. |
| ALB Controller logs | Translation events from Gateway and HTTPRoute to AGC config, ARM call errors. | ARM 403 or 429 from the controller (indicates RBAC drift or throttling), repeated reconcile failures on a specific ApplicationLoadBalancer CR. |
| Microsoft Defender for Containers | Runtime threats: known malicious binaries, suspicious process trees, container drift. See [Defender for Containers introduction](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-containers-introduction). | Any high-severity alert in the `azure-alb-system` namespace or in workload namespaces serving routes. |
| AKS node logs (kubelet) | Pod lifecycle, image pulls, mount events. | alb-controller pod restart loop, image pull failures from MCR. |

Minimum baseline alerts to wire before production cutover:

- AGC frontend 5xx rate exceeds 1% of total requests over a 5 minute window.
- kube-audit event for `httproutes` create or update from a service account outside an explicit allowlist.
- alb-controller pod restart count greater than 3 in 15 minutes.
- ARM 403 from the ALB Controller managed identity (indicates role assignment drift).

## Key risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Overexposed AGC listeners or wildcard host rules | Unintended external access | Limit listeners and hostnames to approved routes. Review Gateway and HTTPRoute objects in PR before apply. |
| Broad NSG allow rules during migration | Lateral movement and bypass of segmentation | Use explicit allow rules with source and destination scoping. Remove temporary rules after cutover validation. |
| Firewall allowlists incomplete | Outage during cutover | Run migration in dry-run phases. Use firewall logs to build and validate allowlists before switching traffic. |
| No backend TLS or weak cert validation | MITM risk on internal path | Enforce backend TLS policies and certificate verification for sensitive services. |
| Controller feature mismatch for mTLS expectations | Security gap versus design intent | Verify capabilities for current AGC and Gateway API versions in staging. Track exceptions in runbook and risk register. |

## Migration cutover risks

Migration moves traffic from `ingress-nginx` (or App Routing addon) to AGC. During cutover both ingress paths exist for the same hostname for a finite period. Treat this dual-stack window as a temporary security regression and enumerate the risks.

### Dual-stack period

Both ingress-nginx and AGC are configured for the same hostname during shadow-traffic and canary phases. Expect:

- **Asymmetric session state.** Cookies set by one path may not validate on the other if the upstream service uses sticky sessions backed by ingress affinity. Mitigation: terminate sticky sessions at the workload, not the ingress, before the dual-stack period begins.
- **Auth state divergence.** OAuth callback URLs, CSRF tokens, and OIDC redirect handling can split between paths. Mitigation: validate the auth flow against both ingress paths before traffic shifting starts.
- **Log fragmentation.** Half the requests log via ingress-nginx, half via AGC access logs. Investigate incidents in both during the window.

### DNS TTL

If the public DNS record for the hostname has a long TTL (300 seconds or more), clients keep resolving the old endpoint after a rollback. A 1 hour TTL means a one hour blast radius for any cutover mistake.

Mitigation:

- Lower TTL to 30 to 60 seconds at least 24 hours before the cutover window. The 24 hours allows existing cached responses to expire.
- Keep the low TTL until the new path has run stable for 7 days.
- Raise the TTL back after the old ingress is decommissioned.

### Decommission timing

Two failure modes bookend the decommission:

1. **Too early.** Removing ingress-nginx before AGC is verified stable means rollback requires reinstalling and reconfiguring the old controller. Mitigation: keep ingress-nginx installed and reachable on a private path for 14 days after cutover. Validate with synthetic traffic.
2. **Too late.** Leaving ingress-nginx installed for months invites a developer or SRE to re-enable it for a single workload, recreating the dual-stack risk without the controls of the original cutover. Mitigation: schedule decommission as a tracked task with a hard deadline (typically 30 days post-cutover); remove the Helm release and any CRDs that the workload could re-target.

The decommission window must close. An indefinite dual-stack state turns the migration into a permanent posture regression.

## Minimum review checklist per migration wave

- [ ] External hostnames and listener ports are explicitly approved.
- [ ] NSG inbound and east-west rules follow least privilege.
- [ ] Azure Firewall egress rules are allowlist-based and logged.
- [ ] TLS certificates and rotation process are documented.
- [ ] mTLS requirements are mapped per application tier, including exceptions.
- [ ] Security sign-off recorded before production cutover.
