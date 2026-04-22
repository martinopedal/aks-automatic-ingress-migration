# AI Governance

This repository uses AI-assisted development tools including GitHub Copilot and Squad by Brady Gaster.

## Principles

1. **AI can draft; CI decides.** All code, whether human or AI-authored, must pass the same automated quality and security checks.
2. **Human accountability.** The maintainer reviews and owns every merge. AI output is a draft, not a decision.
3. **Verify, don't trust.** Non-obvious claims, configurations, and architecture decisions must be verified against authoritative sources (Microsoft Learn, upstream specs, the AGC GA matrix, Gateway API docs).
4. **Transparency.** Pull requests must disclose meaningful AI assistance so reviewers know what to scrutinize. The PR template includes an AI disclosure checkbox.
5. **No secrets.** AI tools must never be given access to credentials, tokens, real subscription IDs, or tenant IDs in prompts or code.

## What this means in practice

- Every PR runs CI (terraform fmt+validate, bicep build+lint, kubeconform, helm lint, gitleaks, CodeQL, dependency-review) before merge.
- Branch protection prevents direct pushes to `main`.
- Dependabot scans GitHub Actions and Terraform dependencies weekly.
- gitleaks runs on every PR with a custom config that blocks real-looking GUIDs in non-doc paths.
- The `provenance` rule in [CONTRIBUTING.md](CONTRIBUTING.md) requires every hard-coded Azure identifier (policy ID, role definition ID, recommendation ID) to be tagged `public-builtin`, `public-source <url>`, or `must-not-ship`.
- Co-authored-by trailers (`Copilot <223556219+Copilot@users.noreply.github.com>`) record AI co-authorship.

## AI tools used in this project

- [GitHub Copilot](https://github.com/features/copilot) for code generation and review.
- [Squad](https://github.com/bradygaster/squad) by Brady Gaster for agentic AI team orchestration. Team charter and routing live in [`.squad/`](.squad/).
- [Model Context Protocol](https://modelcontextprotocol.io/) servers (azure-mcp, microsoft-learn, github, kubernetes) used during authoring for grounded lookups.

## Migration content authoring

The migration runbook content (cutover procedures, rollback steps, threat model) is reviewed line-by-line by the maintainer before publishing. AI is allowed to draft, but operationally sensitive content (anything that could brick a production cluster) requires a `runbook-reviewed` label before merge.

## Reporting concerns

If you believe AI-generated content in this repository is inaccurate, insecure, or violates attribution requirements, please open an issue or use the [security reporting process](SECURITY.md).
