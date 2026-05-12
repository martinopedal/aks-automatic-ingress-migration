# Forge: Project Knowledge

## Team-Wide Decisions and Cross-Agent Impact

### 2026-05-12: Migration Plan Schema v1 Versioning and Location Policy

The migration plan schema v1 establishes the orchestration contract consumed by cross-repo systems (e.g., mcp-server-azure-architect). Key decisions documented in `.squad/decisions.md`:

- **Entry point:** `schema/migration-plan.v1.json` (stable URL for external consumers)
- **Canonical schema:** `schemas/migration-plan/v1/schema.json` (versioned directory structure)
- **Version policy:** Breaking changes increment version; entry point remains stable
- **ADR-001 alignment:** This repo orchestrates upstream tools and provides ALZ Corp IaC. Does not re-translate ingress resources.

**Cross-agent impact:** 
- **Atlas:** Use schema structure to map Gateway API phases (prereq, identity, infra, gateway, route, cutover, validate, rollback) to manifest examples
- **Sage:** Runbook phases must align with schema phase enums
- **mcp-server-azure-architect:** Consume stable entry point at `schema/migration-plan.v1.json` for contract discovery

### 2026-05-12: PowerShell Migration Scripts Philosophy

The migration scripts philosophy (read-only-first, human-driven cutover) is canonical per `.squad/decisions.md`:

- All scripts default to dry-run / preview mode; operators must explicitly opt in to writes
- Automated traffic cutover is intentionally excluded (DNS, traffic validation, monitoring are human gates)
- Each script has single responsibility: Convert, Assess, or Checklist generation

**Cross-agent impact:**
- **Sage:** Runbook must integrate PowerShell scripts as tools, not orchestrators. Operators execute scripts and follow checklists.
- **Atlas:** Manifest translation is a tool boundary; scripts do not patch live resources.
- **Integration patterns:** Scripts compose in operator-defined workflows; no one-click cutover.

## Learnings

### 2026-05-12: API Version Recency Check (trafficControllers)

Verified and bumped `Microsoft.ServiceNetworking/trafficControllers` from `@2023-11-01` to `@2025-01-01` (latest GA stable) across 6 files in PR #TBD.

**Key lesson:** API version recency matters. Before claiming "latest stable", verify by fetching the version-specific ARM template reference page, not just the unversioned index. MS Learn changelog confirmed 2025-01-01 was GA stable with no breaking changes from 2023-11-01.

**Process:**
1. Fetched https://learn.microsoft.com/azure/templates/microsoft.servicenetworking/trafficcontrollers to confirm available versions
2. Fetched version-specific pages for 2023-11-01 and 2025-01-01 to compare schemas
3. Verified change log confirmed "No properties added, updated or removed" for 2025-01-01
4. Confirmed our usage (`properties: {}` with no optional fields) was safe to bump
5. Updated all 6 files to cite version-specific URLs (not unversioned pages)
6. Ran `terraform validate` and `az bicep build` to confirm both stacks parse

**Citation pattern:** Use version-specific URLs in code comments and docs: `https://learn.microsoft.com/azure/templates/microsoft.servicenetworking/2025-01-01/trafficcontrollers (accessed 2026-05-12)`.

### 2026-04-22: Migration Plan Schema v1

Published the migration plan schema v1 contract in PR #46. Key components:

- **Entry point**: `schema/migration-plan.v1.json` - compatibility entry point with `$ef` to canonical schema
- **Canonical schema**: `schemas/migration-plan/v1/schema.json` - JSON Schema draft 2020-12 that defines the structure
- **Location pattern**: Entry points in `schema/` for discoverability, canonical schemas in `schemas/{resource}/{version}/schema.json` for versioning
- **Examples**: Both JSON and YAML formats in `schemas/migration-plan/v1/examples/`

Per ADR-001, this schema is the orchestration contract consumed by mcp-server-azure-architect. This repo does not re-translate ingress resources. The schema coordinates upstream tools (ingress2gateway) and provides ALZ Corp IaC workflows.

Schema structure defines migration steps with phase enums (prereq, identity, infra, gateway, route, cutover, validate, rollback) and action types (manual, kubectl, helm, terraform, bicep, powershell).

Versioning policy: breaking changes increment version (v1 to v2). Entry point remains at `schema/migration-plan.v1.json` for stable consumers.
