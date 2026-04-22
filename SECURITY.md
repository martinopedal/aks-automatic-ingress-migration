# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, report it responsibly using [GitHub Security Advisories](https://github.com/martinopedal/aks-automatic-ingress-migration/security/advisories/new).

Do not open a public issue. Public disclosure before a fix is in place puts users at risk.

The maintainer will acknowledge the report within 5 business days and aim to release a fix within 30 days for confirmed vulnerabilities.

## Supported Versions

Only the latest version on the `main` branch is supported with security updates.

## Scope

This repo ships **infrastructure-as-code, Kubernetes manifests, and runbook content** for migrating AKS ingress to Application Gateway for Containers (AGC). It does not run as a service and does not transmit data externally.

Relevant vulnerability classes include:

- Insecure defaults in Bicep or Terraform that weaken cluster, identity, or network posture
- Workflow injection in GitHub Actions
- Supply chain issues in pinned tool versions, container images, or Helm charts
- Credential or secret leakage in example values, output files, or logs
- Manifest patterns that expose workloads beyond the documented threat model

## Not in scope

This repo is **not an official Microsoft product**. It is a personal community runbook. For Microsoft-supported migration tooling, see [Application-Gateway-for-Containers-Migration-Utility](https://github.com/Azure/Application-Gateway-for-Containers-Migration-Utility).
