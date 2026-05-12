# Architecture Decision Records

*Not an official Microsoft product. Community migration toolkit. See LICENSE.*

---

This directory contains architecture decision records (ADRs) for the aks-automatic-ingress-migration project. Each ADR documents a significant architectural decision, the reasoning behind it, and the consequences.

This index includes both Accepted ADRs (active decisions) and Proposed ADRs (awaiting user decision).

| ADR | Status | Date | Title |
|-----|--------|------|-------|
| [001](./ADR-001-positioning-vs-upstream-tools.md) | Accepted | 2026-04-22 | Positioning vs upstream tools |
| [002](./ADR-002-bicep-terraform-parity-contract.md) | Accepted | 2026-04-22 | Bicep and Terraform parity contract |
| [003](./ADR-003-agc-private-cluster-preview-gate.md) | Accepted | 2026-04-22 | AGC private cluster preview status gate |
| [004](./ADR-004-toolkit-posture-on-preview-features.md) | Accepted | 2026-05-13 | Toolkit posture on preview features |

## How to add an ADR

1. Create a new file named `ADR-NNN-title-slug.md` where NNN is the next sequential number.
2. Copy the template below and fill in the sections.
3. Update the table above with the new ADR number, status, date, and title.
4. Add the disclaimer (`*Not an official Microsoft product. Community migration toolkit. See LICENSE.*`) at the top of the file below the main heading.
5. Open a PR. ADRs require at least one non-author reviewer per team decision policy.

## Template

```markdown
# ADR-NNN: Decision title

*Not an official Microsoft product. Community migration toolkit. See LICENSE.*

**Status:** Proposed | Accepted | Superseded  
**Date:** YYYY-MM-DD  
**Deciders:** [Team member names]

## Context

[Explain the context and problem statement.]

## Decision

[State the decision and any constraints or requirements.]

## Consequences

### Positive

[List positive outcomes.]

### Negative

[List risks or downsides.]

## References

- [Link to supporting documentation]
```

## Decision log

For a history of how decisions are made and approved, see [`.squad/decisions.md`](../../.squad/decisions.md).
