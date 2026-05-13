#!/usr/bin/env bash
# examples/hello-world/smoke/deploy.sh
#
# Live AGC dataplane smoke deployment for use by .github/workflows/smoke-test.yml.
#
# Provisions an end-to-end Application Gateway for Containers (AGC) data path on
# top of a fresh standard AKS cluster, deploys a trivial echo workload behind a
# Gateway API Gateway + HTTPRoute, and writes the resulting public AGC frontend
# URL to the env file the workflow consumes for HTTP probes.
#
# This script is for the automated smoke environment only. It diverges from the
# repo's ALZ Corp default architecture posture (private API, internal AGC) in
# two intentional ways so the GitHub-hosted runner can probe it:
#
#   1. The Gateway uses gatewayClassName=azure-alb-external (public frontend).
#   2. The cluster is standard AKS, not AKS Automatic, because the documented
#      Helm install path is only supported on standard AKS per the AGC FAQ
#      (https://learn.microsoft.com/azure/application-gateway/for-containers/faq).
#      AKS Automatic users follow docs/aks-automatic-path.md.
#
# References:
# - https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-helm
# - https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-managed-by-alb-controller
# - https://learn.microsoft.com/azure/aks/workload-identity-overview
#
# Inputs (all required):
#   --resource-group <name>   Pre-existing resource group (created by the workflow).
#   --location <region>       Azure region. Must be in docs/agc-region-matrix.md.
#   --output-file <path>      Env file path. AGC_URL and EXPECTED_BODY are appended.
#
# Exit codes:
#   0  smoke environment is up, AGC_URL written, first probe returned HTTP 200.
#   1+ deployment failed; diagnostics dumped to stdout before exit.

set -euo pipefail

# ---------------------------------------------------------------------------
# Pinned versions and well-known IDs.
# Bump deliberately and document the bump in the PR.
# ---------------------------------------------------------------------------

# ALB Controller Helm chart version per the current MS Learn quickstart, accessed
# 2026-05-13: https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-helm
ALB_CONTROLLER_CHART_VERSION="${ALB_CONTROLLER_CHART_VERSION:-1.10.27}"

# AKS Kubernetes baseline. Gateway API v1 is GA on AKS 1.30 and later
# (per docs/compatibility-matrix.md).
AKS_K8S_VERSION="${AKS_K8S_VERSION:-1.30}"

# Built-in role IDs for ALB Controller managed identity (per MS Learn):
ROLE_AGFC_CONFIG_MANAGER="fbc52c3f-28ad-4303-a892-8a056630b8f1"  # AppGw for Containers Configuration Manager
ROLE_NETWORK_CONTRIBUTOR="4d97b98b-1d4f-4787-a291-c67834d212e7"  # Network Contributor
ROLE_READER="acdd72a7-3385-48ef-bd42-f606fba81ae7"               # Reader

# Cluster sizing kept small to bound cost (~$0.50-$1 per smoke run for ~20 min).
AKS_NODE_COUNT="${AKS_NODE_COUNT:-1}"
AKS_NODE_VM_SIZE="${AKS_NODE_VM_SIZE:-Standard_B2s}"

# Deterministic names within the run-scoped RG.
ALB_IDENTITY_NAME="azure-alb-identity"
ALB_NAMESPACE="azure-alb-system"
ALB_INFRA_NAMESPACE="alb-test-infra"
ALB_CR_NAME="smoke-alb"
SMOKE_NAMESPACE="smoke"
SMOKE_APP_NAME="hello-world"
SMOKE_TEXT="hello from AGC"

# ---------------------------------------------------------------------------
# Argument parsing.
# ---------------------------------------------------------------------------

RESOURCE_GROUP=""
LOCATION=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
    --location)       LOCATION="$2";       shift 2 ;;
    --output-file)    OUTPUT_FILE="$2";    shift 2 ;;
    -h|--help)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$RESOURCE_GROUP" || -z "$LOCATION" || -z "$OUTPUT_FILE" ]]; then
  echo "ERROR: --resource-group, --location, and --output-file are all required" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Logging helpers.
# ---------------------------------------------------------------------------

log()  { printf '[smoke %s] %s\n' "$(date -u +%H:%M:%S)" "$*"; }
warn() { printf '[smoke %s] WARN: %s\n' "$(date -u +%H:%M:%S)" "$*" >&2; }
die()  { printf '[smoke %s] FATAL: %s\n' "$(date -u +%H:%M:%S)" "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Diagnostics dump on any failure, before the workflow's teardown deletes the RG.
# ---------------------------------------------------------------------------

NODE_RG=""        # populated after AKS create
ALB_PRINCIPAL=""  # populated after MI create

dump_diagnostics() {
  local exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    return 0
  fi
  warn "deploy failed with exit code ${exit_code}, dumping diagnostics"
  {
    echo "----- az account -----"
    az account show -o table 2>&1 || true
    echo "----- resource group -----"
    az group show --name "$RESOURCE_GROUP" -o table 2>&1 || true
    echo "----- AKS cluster -----"
    az aks show --name "smoke-aks" --resource-group "$RESOURCE_GROUP" -o table 2>&1 || true
    if [[ -n "${NODE_RG:-}" ]]; then
      echo "----- node resource group: $NODE_RG -----"
      az resource list --resource-group "$NODE_RG" -o table 2>&1 || true
    fi
    if [[ -n "${ALB_PRINCIPAL:-}" ]]; then
      echo "----- role assignments for ALB managed identity -----"
      az role assignment list --assignee "$ALB_PRINCIPAL" --all -o table 2>&1 || true
    fi
    echo "----- cluster pods (all namespaces) -----"
    kubectl get pods -A -o wide 2>&1 || true
    echo "----- gatewayclass -----"
    kubectl get gatewayclass -o yaml 2>&1 || true
    echo "----- applicationloadbalancer -----"
    kubectl get applicationloadbalancer -A -o yaml 2>&1 || true
    echo "----- gateway -----"
    kubectl get gateway -A -o yaml 2>&1 || true
    echo "----- httproute -----"
    kubectl get httproute -A -o yaml 2>&1 || true
    echo "----- alb-controller logs (tail 200) -----"
    kubectl logs -n "$ALB_NAMESPACE" deploy/alb-controller --tail=200 2>&1 || true
  } >&2
  return $exit_code
}
trap dump_diagnostics EXIT

# ---------------------------------------------------------------------------
# Preflight: required tools.
# ---------------------------------------------------------------------------

require() {
  command -v "$1" >/dev/null 2>&1 || die "required tool not found in PATH: $1"
}
require az
require kubectl
require helm
require jq
require curl

log "preflight tools OK"
log "resource group: $RESOURCE_GROUP"
log "location:       $LOCATION"
log "output file:    $OUTPUT_FILE"
log "k8s baseline:   $AKS_K8S_VERSION"
log "ALB chart:      $ALB_CONTROLLER_CHART_VERSION"

# ---------------------------------------------------------------------------
# Step 1: Register Azure providers (idempotent, with wait).
# ---------------------------------------------------------------------------

PROVIDERS=(
  "Microsoft.ContainerService"
  "Microsoft.Network"
  "Microsoft.NetworkFunction"
  "Microsoft.ServiceNetworking"
  "Microsoft.ManagedIdentity"
)

log "registering providers (idempotent)"
for ns in "${PROVIDERS[@]}"; do
  current=$(az provider show --namespace "$ns" --query registrationState -o tsv 2>/dev/null || echo "NotRegistered")
  if [[ "$current" != "Registered" ]]; then
    log "  registering $ns (state was $current)"
    az provider register --namespace "$ns" --wait
  else
    log "  $ns already Registered"
  fi
done

# ---------------------------------------------------------------------------
# Step 2: Networking. VNet with two subnets: AKS nodes + AGC association.
# ---------------------------------------------------------------------------

VNET_NAME="vnet-smoke"
AKS_SUBNET_NAME="aks-subnet"
ALB_SUBNET_NAME="alb-subnet"
VNET_ADDRESS="10.224.0.0/12"
AKS_SUBNET_ADDRESS="10.224.0.0/16"
ALB_SUBNET_ADDRESS="10.225.0.0/24"

log "creating VNet $VNET_NAME"
az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --name "$VNET_NAME" \
  --address-prefixes "$VNET_ADDRESS" \
  --subnet-name "$AKS_SUBNET_NAME" \
  --subnet-prefixes "$AKS_SUBNET_ADDRESS" \
  -o none

log "creating AGC delegated subnet $ALB_SUBNET_NAME"
az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$ALB_SUBNET_NAME" \
  --address-prefixes "$ALB_SUBNET_ADDRESS" \
  --delegations "Microsoft.ServiceNetworking/trafficControllers" \
  -o none

AKS_SUBNET_ID=$(az network vnet subnet show \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$AKS_SUBNET_NAME" \
  --query id -o tsv)
ALB_SUBNET_ID=$(az network vnet subnet show \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$ALB_SUBNET_NAME" \
  --query id -o tsv)

[[ -n "$AKS_SUBNET_ID" && -n "$ALB_SUBNET_ID" ]] || die "subnet IDs not resolved"
log "AKS subnet: $AKS_SUBNET_ID"
log "ALB subnet: $ALB_SUBNET_ID"

# ---------------------------------------------------------------------------
# Step 3: AKS cluster (standard, Workload Identity + OIDC issuer).
# ---------------------------------------------------------------------------

AKS_NAME="smoke-aks"

log "creating AKS cluster $AKS_NAME (this takes ~5-7 min)"
az aks create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_NAME" \
  --location "$LOCATION" \
  --kubernetes-version "$AKS_K8S_VERSION" \
  --enable-oidc-issuer \
  --enable-workload-identity \
  --network-plugin azure \
  --vnet-subnet-id "$AKS_SUBNET_ID" \
  --node-count "$AKS_NODE_COUNT" \
  --node-vm-size "$AKS_NODE_VM_SIZE" \
  --no-ssh-key \
  --generate-ssh-keys \
  -o none

NODE_RG=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --query nodeResourceGroup -o tsv)
NODE_RG_ID=$(az group show --name "$NODE_RG" --query id -o tsv)
OIDC_ISSUER=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --query oidcIssuerProfile.issuerUrl -o tsv)
[[ -n "$NODE_RG" && -n "$NODE_RG_ID" && -n "$OIDC_ISSUER" ]] || die "AKS metadata not resolved"
log "MC_ resource group: $NODE_RG"
log "OIDC issuer:        $OIDC_ISSUER"

# Persist NODE_RG to the env file early so teardown can clean it up even if a
# later step fails.
echo "NODE_RG=$NODE_RG" >> "$OUTPUT_FILE"

log "fetching cluster credentials (admin)"
az aks get-credentials \
  --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_NAME" \
  --admin \
  --overwrite-existing \
  -o none

kubectl get nodes -o wide

# ---------------------------------------------------------------------------
# Step 4: User-assigned managed identity for the ALB controller.
# ---------------------------------------------------------------------------

log "creating user-assigned managed identity $ALB_IDENTITY_NAME"
az identity create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ALB_IDENTITY_NAME" \
  --location "$LOCATION" \
  -o none

ALB_PRINCIPAL=$(az identity show --resource-group "$RESOURCE_GROUP" --name "$ALB_IDENTITY_NAME" --query principalId -o tsv)
ALB_CLIENT_ID=$(az identity show --resource-group "$RESOURCE_GROUP" --name "$ALB_IDENTITY_NAME" --query clientId -o tsv)
[[ -n "$ALB_PRINCIPAL" && -n "$ALB_CLIENT_ID" ]] || die "managed identity ids not resolved"
log "MI principal: $ALB_PRINCIPAL"
log "MI clientId:  $ALB_CLIENT_ID"

# Identity propagation can take ~30s before role assignments stick.
log "waiting 30s for managed identity replication"
sleep 30

# ---------------------------------------------------------------------------
# Step 5: Role assignments per MS Learn ALB Controller Helm quickstart.
# ---------------------------------------------------------------------------

assign_role() {
  local scope="$1" role_id="$2" role_label="$3"
  local attempt
  for attempt in 1 2 3 4 5; do
    if az role assignment create \
        --assignee-object-id "$ALB_PRINCIPAL" \
        --assignee-principal-type ServicePrincipal \
        --scope "$scope" \
        --role "$role_id" \
        -o none 2>/dev/null; then
      log "  ${role_label}: assigned (attempt ${attempt})"
      return 0
    fi
    warn "  ${role_label}: assignment failed (attempt ${attempt}), retrying in 15s"
    sleep 15
  done
  die "failed to assign ${role_label} after 5 attempts"
}

log "assigning RBAC roles to ALB managed identity"
assign_role "$NODE_RG_ID"    "$ROLE_AGFC_CONFIG_MANAGER" "AppGw for Containers Configuration Manager on MC_ RG"
assign_role "$NODE_RG_ID"    "$ROLE_READER"              "Reader on MC_ RG"
assign_role "$ALB_SUBNET_ID" "$ROLE_NETWORK_CONTRIBUTOR" "Network Contributor on ALB subnet"

# ---------------------------------------------------------------------------
# Step 6: Federate the managed identity to the ALB controller service account.
# ---------------------------------------------------------------------------

log "federating MI to system:serviceaccount:${ALB_NAMESPACE}:alb-controller-sa"
az identity federated-credential create \
  --resource-group "$RESOURCE_GROUP" \
  --identity-name "$ALB_IDENTITY_NAME" \
  --name "alb-controller-sa-fed" \
  --issuer "$OIDC_ISSUER" \
  --subject "system:serviceaccount:${ALB_NAMESPACE}:alb-controller-sa" \
  --audiences "api://AzureADTokenExchange" \
  -o none

# Federated credential propagation can take up to a minute before tokens validate.
log "waiting 60s for federated credential propagation"
sleep 60

# ---------------------------------------------------------------------------
# Step 7: Install ALB Controller via Helm (managed-by-controller mode).
# ---------------------------------------------------------------------------

log "installing ALB Controller chart $ALB_CONTROLLER_CHART_VERSION into namespace $ALB_NAMESPACE"
helm upgrade --install alb-controller \
  oci://mcr.microsoft.com/application-lb/charts/alb-controller \
  --version "$ALB_CONTROLLER_CHART_VERSION" \
  --namespace "$ALB_NAMESPACE" \
  --create-namespace \
  --set albController.podIdentity.clientID="$ALB_CLIENT_ID" \
  --wait \
  --timeout 5m

log "waiting for alb-controller rollout"
kubectl rollout status -n "$ALB_NAMESPACE" deploy/alb-controller --timeout=5m

# ---------------------------------------------------------------------------
# Step 8: ApplicationLoadBalancer custom resource (triggers AGC creation).
# ---------------------------------------------------------------------------

log "creating namespace $ALB_INFRA_NAMESPACE"
kubectl create namespace "$ALB_INFRA_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

log "applying ApplicationLoadBalancer $ALB_CR_NAME"
kubectl apply -f - <<EOF
apiVersion: alb.networking.azure.io/v1
kind: ApplicationLoadBalancer
metadata:
  name: ${ALB_CR_NAME}
  namespace: ${ALB_INFRA_NAMESPACE}
spec:
  associations:
  - ${ALB_SUBNET_ID}
EOF

# Per MS Learn, AGC provisioning takes 5-6 minutes. Wait up to 12 to be safe.
log "waiting for ApplicationLoadBalancer to reach Deployment=True (up to 12 min)"
deadline=$(( $(date +%s) + 720 ))
while :; do
  status=$(kubectl get applicationloadbalancer "$ALB_CR_NAME" -n "$ALB_INFRA_NAMESPACE" -o json 2>/dev/null \
    | jq -r '.status.conditions[]? | select(.type=="Deployment") | .status' 2>/dev/null || echo "")
  if [[ "$status" == "True" ]]; then
    log "  ApplicationLoadBalancer Deployment=True"
    break
  fi
  if (( $(date +%s) > deadline )); then
    die "ApplicationLoadBalancer did not reach Deployment=True within 12 min"
  fi
  printf '.'
  sleep 15
done
echo ""

# ---------------------------------------------------------------------------
# Step 9: Smoke workload + Gateway + HTTPRoute (managed-by-controller binding
# via annotations, NOT parametersRef).
# ---------------------------------------------------------------------------

log "creating namespace $SMOKE_NAMESPACE"
kubectl create namespace "$SMOKE_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

log "deploying ${SMOKE_APP_NAME} workload + Gateway + HTTPRoute"
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${SMOKE_APP_NAME}
  namespace: ${SMOKE_NAMESPACE}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${SMOKE_APP_NAME}
  template:
    metadata:
      labels:
        app: ${SMOKE_APP_NAME}
    spec:
      containers:
        - name: echo
          image: hashicorp/http-echo:1.0.0
          args: ["-text=${SMOKE_TEXT}"]
          ports:
            - name: http
              containerPort: 5678
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            runAsUser: 10001
            capabilities:
              drop: [ALL]
---
apiVersion: v1
kind: Service
metadata:
  name: ${SMOKE_APP_NAME}
  namespace: ${SMOKE_NAMESPACE}
spec:
  selector:
    app: ${SMOKE_APP_NAME}
  ports:
    - name: http
      port: 80
      targetPort: 5678
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: ${SMOKE_APP_NAME}
  namespace: ${SMOKE_NAMESPACE}
  annotations:
    alb.networking.azure.io/alb-namespace: ${ALB_INFRA_NAMESPACE}
    alb.networking.azure.io/alb-name: ${ALB_CR_NAME}
spec:
  gatewayClassName: azure-alb-external
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: ${SMOKE_APP_NAME}
  namespace: ${SMOKE_NAMESPACE}
spec:
  parentRefs:
    - name: ${SMOKE_APP_NAME}
      sectionName: http
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: ${SMOKE_APP_NAME}
          port: 80
EOF

log "waiting for Gateway to be Programmed (up to 5 min)"
deadline=$(( $(date +%s) + 300 ))
while :; do
  programmed=$(kubectl get gateway "$SMOKE_APP_NAME" -n "$SMOKE_NAMESPACE" -o json 2>/dev/null \
    | jq -r '.status.conditions[]? | select(.type=="Programmed") | .status' 2>/dev/null || echo "")
  if [[ "$programmed" == "True" ]]; then
    log "  Gateway Programmed=True"
    break
  fi
  if (( $(date +%s) > deadline )); then
    die "Gateway did not reach Programmed=True within 5 min"
  fi
  printf '.'
  sleep 10
done
echo ""

log "waiting for HTTPRoute to be Accepted+ResolvedRefs (up to 2 min)"
deadline=$(( $(date +%s) + 120 ))
while :; do
  accepted=$(kubectl get httproute "$SMOKE_APP_NAME" -n "$SMOKE_NAMESPACE" -o json 2>/dev/null \
    | jq -r '.status.parents[0].conditions[]? | select(.type=="Accepted") | .status' 2>/dev/null || echo "")
  resolved=$(kubectl get httproute "$SMOKE_APP_NAME" -n "$SMOKE_NAMESPACE" -o json 2>/dev/null \
    | jq -r '.status.parents[0].conditions[]? | select(.type=="ResolvedRefs") | .status' 2>/dev/null || echo "")
  if [[ "$accepted" == "True" && "$resolved" == "True" ]]; then
    log "  HTTPRoute Accepted=True ResolvedRefs=True"
    break
  fi
  if (( $(date +%s) > deadline )); then
    die "HTTPRoute did not reach Accepted+ResolvedRefs within 2 min"
  fi
  printf '.'
  sleep 5
done
echo ""

# ---------------------------------------------------------------------------
# Step 10: Resolve the public AGC frontend FQDN from the Gateway status.
# ---------------------------------------------------------------------------

GATEWAY_FQDN=$(kubectl get gateway "$SMOKE_APP_NAME" -n "$SMOKE_NAMESPACE" \
  -o jsonpath='{.status.addresses[0].value}')
[[ -n "$GATEWAY_FQDN" ]] || die "Gateway has no programmed address"
AGC_URL="http://${GATEWAY_FQDN}/"
log "Gateway FQDN: $GATEWAY_FQDN"

# ---------------------------------------------------------------------------
# Step 11: Self-check probe with retry. AGC dataplane warmup can take ~60s
# after the Gateway is Programmed before the listener returns 200.
# ---------------------------------------------------------------------------

log "self-checking $AGC_URL (up to 3 min)"
deadline=$(( $(date +%s) + 180 ))
while :; do
  body=$(curl -sS --max-time 5 "$AGC_URL" || echo "")
  if [[ "$body" == *"$SMOKE_TEXT"* ]]; then
    log "  self-check passed: body contains '$SMOKE_TEXT'"
    break
  fi
  if (( $(date +%s) > deadline )); then
    die "self-check did not return expected body within 3 min (last body: $body)"
  fi
  printf '.'
  sleep 5
done
echo ""

# ---------------------------------------------------------------------------
# Step 12: Hand off the URL to the workflow's probe step.
# ---------------------------------------------------------------------------

{
  echo "AGC_URL=${AGC_URL}"
  echo "EXPECTED_BODY=${SMOKE_TEXT}"
} >> "$OUTPUT_FILE"

log "deploy complete. Wrote AGC_URL=${AGC_URL} to ${OUTPUT_FILE}"
