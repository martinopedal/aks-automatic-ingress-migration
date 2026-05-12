# Compatibility matrix

**Owner:** Atlas (`squad:atlas`)  
**Review cadence:** Quarterly  
**Last reviewed:** 2026-04-22

This matrix tracks the validated version set for AKS Automatic migration work in this repository.

## Sources

- AKS supported Kubernetes versions: <https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions>
- AKS release tracker: <https://releases.aks.azure.com/>
- AGC ALB Controller release notes: <https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/alb-controller-release-notes>
- Gateway API releases: <https://github.com/kubernetes-sigs/gateway-api/releases>
- ingress2gateway releases: <https://github.com/kubernetes-sigs/ingress2gateway/releases>
- ingress2gateway v1.0.0 release (2026-03-20): <https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.0.0>
- Kubernetes blog, ingress2gateway 1.0 release (2026-03-20): <https://kubernetes.io/blog/2026/03/20/ingress2gateway-1-0-release/>

## Matrix

| Component | Version | Source | Notes |
|---|---|---|---|
| AKS Automatic | 1.30.x and later | [AKS Supported Kubernetes Versions](https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions), [AKS Release Tracker](https://releases.aks.azure.com/) | Gateway API v1 promoted to GA in Kubernetes 1.29. AKS Automatic 1.30+ recommended for stable Gateway API support. Access date: 2026-05-12. |
| Gateway API CRDs | v1 (GA) | [Gateway API Releases](https://github.com/kubernetes-sigs/gateway-api/releases), [Gateway API v1.0.0](https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.0.0) | Gateway and HTTPRoute promoted to v1 in Gateway API v1.0.0 release (2024-10-30). Access date: 2026-05-12. |
| AGC ALB Controller | latest stable | [ALB Controller Release Notes](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/alb-controller-release-notes), [Quickstart: Deploy AGC](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers) | Install via Helm chart from Microsoft. Track release notes for version-specific behavior. Access date: 2026-05-12. |
| ingress2gateway | v1.0.0 and later | [ingress2gateway Releases](https://github.com/kubernetes-sigs/ingress2gateway/releases), [v1.0.0 Release (2026-03-20)](https://github.com/kubernetes-sigs/ingress2gateway/releases/tag/v1.0.0) | Automated ingress-nginx to Gateway API translation tool. v1.0.0 baseline per Kubernetes blog (2026-03-20). Access date: 2026-05-12. |
| ingress-nginx (legacy) | tracked for reference | [ingress-nginx Releases](https://github.com/kubernetes/ingress-nginx/releases) | App Routing addon retirement planned Nov 2026. Track for annotation compatibility mapping. Access date: 2026-05-12. |

## Refresh procedure

1. Check all sources in this file.
2. Update the matrix row for the current quarter.
3. Update `Last reviewed`.
4. Link the update PR to the quarterly refresh issue.
