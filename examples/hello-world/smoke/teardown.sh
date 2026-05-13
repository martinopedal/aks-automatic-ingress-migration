#!/usr/bin/env bash
# examples/hello-world/smoke/teardown.sh
#
# Teardown wrapper invoked by .github/workflows/smoke-test.yml after probing.
#
# The workflow's final step is `az group delete --name <RG> --yes` which removes
# the smoke resource group and everything inside it (VNet, AKS, AGC, MI, ALB
# subnet, federated credentials, role assignments scoped to in-RG resources).
#
# This script handles the one weak point that lives outside that RG: the AKS
# node resource group (`MC_<rg>_<aks>_<region>`). AKS normally cleans this up
# when the cluster is deleted, but if AKS deletion partially fails or the
# control plane was never reached, the MC_ RG can linger. This script does a
# best-effort delete on it so we don't accumulate orphans.
#
# Inputs:
#   --resource-group <name>   Smoke resource group (the workflow deletes this next).
#   --location <region>       Azure region (informational).
#
# This script never fails the workflow. It logs warnings and exits 0.

set -uo pipefail

RESOURCE_GROUP=""
LOCATION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
    --location)       LOCATION="$2";       shift 2 ;;
    *) shift ;;
  esac
done

log() { printf '[teardown %s] %s\n' "$(date -u +%H:%M:%S)" "$*"; }

log "resource group: ${RESOURCE_GROUP:-<unset>}"
log "location:       ${LOCATION:-<unset>}"

# 1. Try to capture the node resource group via the live AKS resource (best effort,
#    may already be gone if the workflow deleted things out of order).
NODE_RG=""
if [[ -n "$RESOURCE_GROUP" ]] && command -v az >/dev/null 2>&1; then
  NODE_RG=$(az aks show --resource-group "$RESOURCE_GROUP" --name "smoke-aks" \
    --query nodeResourceGroup -o tsv 2>/dev/null || echo "")
fi

# 2. Fall back to the value the deploy script wrote to the env file, if the
#    workflow exported the path via $SMOKE_ENV_FILE.
if [[ -z "$NODE_RG" && -n "${SMOKE_ENV_FILE:-}" && -f "${SMOKE_ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${SMOKE_ENV_FILE}" || true
  NODE_RG="${NODE_RG:-}"
fi

if [[ -z "$NODE_RG" ]]; then
  log "no node resource group resolvable; nothing to clean up out-of-RG"
  exit 0
fi

log "best-effort delete of MC_ resource group: $NODE_RG"
if az group exists --name "$NODE_RG" 2>/dev/null | grep -q true; then
  if az group delete --name "$NODE_RG" --yes --no-wait 2>&1; then
    log "  delete initiated (no-wait)"
  else
    log "  delete returned non-zero (will rely on AKS auto-cleanup)"
  fi
else
  log "  $NODE_RG does not exist (already cleaned up by AKS or never created)"
fi

exit 0
