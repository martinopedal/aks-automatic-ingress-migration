# Compatibility Matrix

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

| Review cycle | AKS Automatic (Kubernetes) | AGC ALB Controller | Gateway API | ingress2gateway | Notes |
|---|---|---|---|---|---|
| 2026-Q2 | Track from AKS supported versions and release tracker | Track from Microsoft ALB Controller release notes | v1 CRD track, verify against gateway-api releases and ALB Controller notes | v1.0.0 baseline | Initial matrix baseline for this repo |

## Refresh Procedure

1. Check all sources in this file.
2. Update the matrix row for the current quarter.
3. Update `Last reviewed`.
4. Link the update PR to the quarterly refresh issue.
