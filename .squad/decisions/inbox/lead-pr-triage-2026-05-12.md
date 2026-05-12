# PR Triage Decision: 2026-05-12

**Author:** Lead
**Scope:** 10 draft @copilot PRs (#23, #24, #25, #26, #27, #28, #29, #35, #36, #37)

## Summary

8 PRs approved and marked ready for review. Auto-merge workflow will squash-merge when CI passes and code owner approves.
2 PRs left in draft with REQUEST_CHANGES comments.

## Triage Table

| PR | Title | Verdict | Trade-off / Issue |
|---|---|---|---|
| #23 | ALZ Corp hello-world sample | APPROVE | Internal gatewayClassName aligns with ALZ Corp posture |
| #24 | Ingress -> Gateway manifest catalog | APPROVE | External gateway for catalog demos, internal for hello-world |
| #25 | Live AKS+AGC smoke workflow | APPROVE | workflow_dispatch + schedule, OIDC documented, graceful skip |
| #26 | AGC controller identity wiring runbook | APPROVE | Workload Identity only, no SP secrets |
| #27 | Sentinel threat model | APPROVE | Scoped to migration path, not full AKS review |
| #28 | Compatibility matrix + quarterly refresh | APPROVE | Manual quarterly refresh, sources cited |
| #29 | Workflow to enforce CI checks | REQUEST_CHANGES | Check name case mismatch: `Analyze (actions)` vs `analyze (actions)` |
| #35 | Bicep: enforce non-empty subnetId | APPROVE | Correct @minLength(1) validator |
| #36 | TF: mirror Bicep AGC location defaulting | APPROVE | Location defaults to RG location with check assertion |
| #37 | Migration plan schema v1 entrypoint | REQUEST_CHANGES | Missing canonical schema file `schemas/migration-plan/v1/schema.json` |

## Notes

- PR #29: GitHub status check names are case-sensitive. The workflow must reference the exact check names as they appear in the Actions UI. The CodeQL job displays as `analyze (actions)` not `Analyze (actions)`.
- PR #37: The entry point references a schema file via `$ref` that was not included in the PR. Examples without a validating schema violate the contract pattern in ADR-001.

## Next steps

- @copilot to address REQUEST_CHANGES on #29 and #37
- Code owner review (martinopedal) triggers auto-merge for the 8 ready PRs
