# Squad Team

> aks-automatic-ingress-migration

## Coordinator

| Name | Role | Notes |
|------|------|-------|
| Squad | Coordinator | Routes work, enforces handoffs and reviewer gates. |

## Members

| Name | Role | Charter | Status |
|------|------|---------|--------|
| Lead | Team Lead and Architect | [charter](agents/lead/charter.md) | Active |
| Atlas | Kubernetes and Gateway API Engineer | [charter](agents/atlas/charter.md) | Active |
| Forge | IaC Engineer (Terraform + Bicep) | [charter](agents/forge/charter.md) | Active |
| Iris | Identity and RBAC Engineer | [charter](agents/iris/charter.md) | Active |
| Sentinel | Security Reviewer | [charter](agents/sentinel/charter.md) | Active |
| Sage | Research and Runbook Author | [charter](agents/sage/charter.md) | Active |
| @copilot | GitHub Coding Agent (cloud, autonomous PRs) | n/a (uses AGENTS.md + ADRs as context) | Active. Manual assignment only. 🟢 small docs/IaC tasks, 🟡 multi-file refactors, 🔴 architecture decisions. |

## Project Context

- **Project:** aks-automatic-ingress-migration, AKS Automatic migration toolkit from ingress-nginx to AGC + Gateway API
- **Stack:** Terraform (azurerm + azapi), Bicep, Helm, Gateway API, PowerShell
- **Created:** 2026-04-22
- **Deadline anchor:** App Routing managed NGINX stops receiving Azure support after November 2026, per the caution callout in [Enable application routing with Gateway API (preview)](https://learn.microsoft.com/azure/aks/app-routing-gateway-api). Upstream `ingress-nginx` project enters maintenance mode in March 2026, per [Ingress NGINX retirement announcement](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/).
