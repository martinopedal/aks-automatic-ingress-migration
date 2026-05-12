# Compatibility matrix

**Owner:** Atlas (`squad:atlas`)  
**Review cadence:** Quarterly  
**Last reviewed:** 2026-05-12  
**Access date:** 2026-05-12

This matrix tracks the validated version set for AKS Automatic migration work in this repository.

## Sources

- AKS supported Kubernetes versions: <https://learn.microsoft.com/azure/aks/supported-kubernetes-versions>
- AKS release tracker: <https://releases.aks.azure.com/>
- AGC ALB Controller release notes: <https://learn.microsoft.com/azure/application-gateway/for-containers/alb-controller-release-notes>
- Gateway API releases: <https://github.com/kubernetes-sigs/gateway-api/releases>
- ingress2gateway releases: <https://github.com/kubernetes-sigs/ingress2gateway/releases>
- App Routing Gateway API implementation: <https://learn.microsoft.com/azure/aks/app-routing-gateway-api>
- AGC ALB Controller AKS add-on: <https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon>
- ingress-nginx retirement blog: <https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/>

## Matrix

| Component | Version | Source | Status | Notes |
|---|---|---|---|---|
| AKS Automatic | 1.30.x and later | [Supported K8s Versions](https://learn.microsoft.com/azure/aks/supported-kubernetes-versions) | GA | Gateway API v1 promoted to GA in Kubernetes 1.29. AKS Automatic 1.30+ is the recommended baseline for stable Gateway API support. Includes pre-configured managed NGINX. |
| Gateway API CRDs | v1 (GA) | [v1.0.0 release](https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.0.0) published 2023-10-31 | GA | Gateway and HTTPRoute resources promoted to v1 API version. Stable for production use. Conformance tests available for implementation validation. |
| AGC ALB Controller (Helm) | latest stable | [ALB Controller Release Notes](https://learn.microsoft.com/azure/application-gateway/for-containers/alb-controller-release-notes) | GA | Installed via Helm chart. Check release notes for version-specific behavior and CVE patches. |
| ingress2gateway | v1.1.0 (latest stable) | [v1.0.0](https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.0.0) (2026-03-20), [v1.1.0](https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.1.0) (2026-04-29) | GA | CLI tool for automated Ingress to HTTPRoute translation. v1.1.0 adds Traefik support, app-root, ssl-passthrough, and from-to-www-redirect annotations for ingress-nginx. |
| App Routing Gateway API impl | preview | [App Routing GA](https://learn.microsoft.com/azure/aks/app-routing-gateway-api) | Preview | AKS-native Gateway API implementation. GatewayClass: `approuting-istio`. Requires `aks-preview` extension >= 19.0.0b24. Istio 1.28+ control plane. |
| AGC ALB Controller AKS add-on | preview | [Quickstart](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon) | Preview | Managed AGC controller deployment. Requires Azure CNI and Workload Identity. Simplifies AGC provisioning without manual Helm installation. |
| ingress-nginx (legacy) | tracked for reference | [ingress-nginx Releases](https://github.com/kubernetes/ingress-nginx/releases), [Retirement notice](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/) | End-of-Life (Mar 2026) | Maintenance support ends March 2026. Annotation compatibility critical for migration planning.

## Refresh procedure

1. Check all sources in this file.
2. Update the matrix row for the current quarter.
3. Update `Last reviewed`.
4. Link the update PR to the quarterly refresh issue.
