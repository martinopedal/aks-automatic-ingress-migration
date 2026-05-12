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

### 2026-04-22: Migration Plan Schema v1

Published the migration plan schema v1 contract in PR #46. Key components:

- **Entry point**: `schema/migration-plan.v1.json` - compatibility entry point with `$ef` to canonical schema
- **Canonical schema**: `schemas/migration-plan/v1/schema.json` - JSON Schema draft 2020-12 that defines the structure
- **Location pattern**: Entry points in `schema/` for discoverability, canonical schemas in `schemas/{resource}/{version}/schema.json` for versioning
- **Examples**: Both JSON and YAML formats in `schemas/migration-plan/v1/examples/`

Per ADR-001, this schema is the orchestration contract consumed by mcp-server-azure-architect. This repo does not re-translate ingress resources. The schema coordinates upstream tools (ingress2gateway) and provides ALZ Corp IaC workflows.

Schema structure defines migration steps with phase enums (prereq, identity, infra, gateway, route, cutover, validate, rollback) and action types (manual, kubectl, helm, terraform, bicep, powershell).

Versioning policy: breaking changes increment version (v1 to v2). Entry point remains at `schema/migration-plan.v1.json` for stable consumers.

### 2026-05-12: IaC README and Identity Scope Clarification

Shipped PR #54 addressing gap audit items #8 (infra half) and #18 (identity gap).

**Files created:**
- `infra/README.md`: Top-level navigation for infra/ directory. Covers parity contract per ADR-002, module tree (agc/ with Terraform/Bicep implementations), links to outputs.schema.json and validate-iac-parity.ps1, canonical provisioning guide (runbook 02), identity scope clarification, ALZ Corp defaults, and API versions.

**Files modified:**
- `examples/hello-world/README.md`: Removed reference to `agc_identity_client_id` output, which neither IaC module exposes. Clarified that identity wiring is Iris's domain per runbook 03.

**Identity scope decision rationale:**

The hello-world README referenced `agc_identity_client_id` as an IaC output, but neither the Terraform nor Bicep module exposes it. Per ADR-002 and decision #2, the IaC modules only handle AGC network and dataplane resources (trafficController, frontend, association). Managed identity creation and Workload Identity federation are Iris's domain per `docs/runbook/03-identity-wiring.md`.

Adding managed identity creation to the IaC modules would require an architecture decision (ADR). This was out of scope for the gap fix. The fix was scoped to documentation only: removed the reference to the missing output and added a note linking to the canonical identity runbook.

**Why doc-fix-only:**
- IaC module scope is network and AGC dataplane only (per ADR-002).
- Identity wiring is a separate concern with distinct RBAC requirements (federated credential creation, role assignments).
- Mixing identity provisioning into the AGC module would couple two orthogonal concerns and violate single responsibility.
- The identity runbook (03) already exists and covers the full process. No need to duplicate or split the logic.

**Learnings:**
- Output schemas are the parity contract. If an output is referenced in examples, it must exist in the schema or the reference is a gap.
- Identity scope decisions must be explicit. Callers expect either (a) IaC provisions identity, or (b) IaC assumes identity exists. Document which pattern is in use.
- When a gap crosses agent boundaries (IaC vs identity), document the boundary explicitly rather than assuming readers will infer it.
