# Live AGC dataplane smoke

This directory contains the deploy and teardown scripts that
[`.github/workflows/smoke-test.yml`](../../../.github/workflows/smoke-test.yml)
invokes during scheduled or `workflow_dispatch` smoke runs.

## What it does

`deploy.sh` provisions a complete AGC data path from scratch in a fresh
resource group:

1. Registers required Azure resource providers.
2. Creates a VNet with two subnets (AKS nodes + AGC association, the latter
   delegated to `Microsoft.ServiceNetworking/trafficControllers`).
3. Creates a small standard AKS cluster with Workload Identity and OIDC issuer
   enabled.
4. Creates a user-assigned managed identity for the ALB Controller, federates
   it to `system:serviceaccount:azure-alb-system:alb-controller-sa`, and
   assigns the three RBAC roles documented in the
   [ALB Controller Helm quickstart](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-helm).
5. Installs the ALB Controller Helm chart from
   `oci://mcr.microsoft.com/application-lb/charts/alb-controller`, pinned to
   the version recorded in `deploy.sh`.
6. Creates an `ApplicationLoadBalancer` custom resource so the controller
   provisions the AGC trafficController + frontend + association on our behalf
   ([managed-by-controller deployment strategy](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-managed-by-alb-controller)).
7. Deploys a trivial `hashicorp/http-echo` workload behind a Gateway and
   HTTPRoute. The Gateway uses `gatewayClassName: azure-alb-external` so the
   GitHub-hosted runner can reach it for HTTP probes, and binds to the
   `ApplicationLoadBalancer` via the documented annotations
   `alb.networking.azure.io/alb-namespace` and `alb.networking.azure.io/alb-name`.
8. Waits for `Programmed=True` on the Gateway and `Accepted+ResolvedRefs=True`
   on the HTTPRoute, runs a self-check curl, and writes `AGC_URL` and
   `EXPECTED_BODY` to the env file the workflow then probes.

`teardown.sh` does best-effort cleanup of the `MC_` node resource group that
AKS normally deletes itself. The workflow's final step is `az group delete`
on the smoke resource group, which removes everything else.

## Smoke divergences from the documented ALZ Corp posture

The smoke run is intentionally not ALZ-shaped. Two divergences:

- **Public Gateway frontend** (`azure-alb-external`). ALZ defaults to
  `azure-alb-internal` per the
  [hello-world example](../README.md), but the GitHub-hosted runner cannot
  reach internal endpoints without a self-hosted runner inside the VNet.
- **Standard AKS, not AKS Automatic.** The Helm install path for the ALB
  Controller is unsupported on AKS Automatic per the
  [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq);
  AKS Automatic users follow [`docs/aks-automatic-path.md`](../../../docs/aks-automatic-path.md).
  This smoke validates the AGC dataplane, not the Automatic-specific add-on
  path.

## Cost and timing

A single smoke run takes ~15 to 20 minutes end to end (AKS create dominates)
and costs ~$0.50 to $1 in transient resources at smallest sizing. The workflow
defaults to the weekly schedule (Mondays 03:00 UTC) plus on-demand
`workflow_dispatch`. The preflight job skips cleanly when the
`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` repository
secrets are absent, so forks no-op.

## Local invocation

You can run `deploy.sh` against your own subscription for one-off testing.

```bash
az login
az account set --subscription <your-sub>

RG=rg-smoke-local-$(date +%s)
ENV_FILE=$(mktemp)
az group create --name "$RG" --location westeurope

examples/hello-world/smoke/deploy.sh \
  --resource-group "$RG" \
  --location westeurope \
  --output-file "$ENV_FILE"

cat "$ENV_FILE"

# Probe a few times then clean up.
source "$ENV_FILE"
curl -sS "$AGC_URL"

examples/hello-world/smoke/teardown.sh --resource-group "$RG" --location westeurope
az group delete --name "$RG" --yes
```

## Pinned versions

`deploy.sh` exposes overridable env vars for the moving parts:

| Variable | Default | Source |
|---|---|---|
| `ALB_CONTROLLER_CHART_VERSION` | `1.10.27` | [Helm quickstart](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-helm) accessed 2026-05-13 |
| `AKS_K8S_VERSION` | `1.30` | [Compatibility matrix](../../../docs/compatibility-matrix.md) |
| `AKS_NODE_COUNT` | `1` | smallest viable smoke cluster |
| `AKS_NODE_VM_SIZE` | `Standard_B2s` | cost-bounded |
