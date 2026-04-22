# Contributing

This is a solo-maintained repository. Contributions are welcome but the maintainer reviews and merges everything.

## Project posture

This repo is a **community migration runbook** for moving AKS ingress workloads to Application Gateway for Containers (AGC). It is **not an official Microsoft product**. For the Microsoft-supported migration utility, see [Application-Gateway-for-Containers-Migration-Utility](https://github.com/Azure/Application-Gateway-for-Containers-Migration-Utility).

## Process

1. Fork the repo
2. Create a branch: `git checkout -b feat/your-change`
3. Make your changes
4. Sign off your commit: `git commit -s -m "feat: describe your change"`
5. Open a pull request against `main`

## Style

- No em dashes in any markdown or code comments. Use commas, parentheses, or rewrite.
- Bicep + Terraform parity: every IaC change in one stack must be mirrored in the other before merge.
- Sample apps under `samples/` must run on AKS Automatic with no public IPs.

## Validation gates

Every PR runs:

- `terraform fmt -check` and `terraform validate`
- `bicep build` and `bicep lint`
- `helm lint` on every chart in `charts/`
- `kubeconform` on every manifest in `manifests/`
- gitleaks
- CodeQL (where applicable)

## Identifier provenance

Any hard-coded Azure identifier (policy ID, initiative ID, role definition ID, recommendation ID) must be tagged in the source with one of:

- `# provenance: public-builtin` (Microsoft built-in resource)
- `# provenance: public-source <repo or doc URL>` (sourced from a public repo or doc)
- `# provenance: must-not-ship` (placeholder, do not merge)

The CI lint will fail any identifier without a provenance tag.

## AI-assisted contributions

AI-assisted contributions are welcome. Disclose AI use in the PR description. The maintainer verifies correctness before merging.

## Commit sign-off

All commits must include a `Signed-off-by` trailer (`git commit -s`). This certifies you wrote the contribution or have the right to submit it under the project license.

Co-authorship by Copilot is recorded with a `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` trailer when applicable.
