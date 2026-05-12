# Phase 03, identity wiring

## Goal

Federate the ALB controller's Kubernetes ServiceAccount to the AGC managed identity using Workload Identity. No service principal secrets in the cluster.

## Prerequisites

- Phase 02 complete (controller installed, AGC provisioned).
- AKS Automatic cluster has **OIDC issuer enabled** and **Workload Identity enabled** (default for Automatic, confirm with `az aks show -g <rg> -n <cluster> --query oidcIssuerProfile`).
- The user-assigned managed identity for AGC was created by the IaC modules. Note its `clientId` and the `principalId` from Phase 02 outputs.

## Steps

### 1. Capture cluster OIDC issuer

```bash
OIDC_ISSUER=$(az aks show -g <rg> -n <cluster> \
  --query oidcIssuerProfile.issuerUrl -o tsv)
echo "$OIDC_ISSUER"
```

### 2. Create federated credential for the ALB controller ServiceAccount

```bash
AGC_IDENTITY_NAME="id-agc-aks-prod"
RG="rg-aks-prod-spoke"

az identity federated-credential create \
  --name "alb-controller-fed" \
  --identity-name "$AGC_IDENTITY_NAME" \
  --resource-group "$RG" \
  --issuer "$OIDC_ISSUER" \
  --subject "system:serviceaccount:azure-alb-system:alb-controller-sa" \
  --audience "api://AzureADTokenExchange"
```

### 3. Grant AGC permissions to the managed identity

```bash
SUB=$(az account show --query id -o tsv)
AGC_RG_SCOPE="/subscriptions/$SUB/resourceGroups/$RG"
AGC_PRINCIPAL_ID=$(az identity show -g "$RG" -n "$AGC_IDENTITY_NAME" --query principalId -o tsv)

# Required by ALB controller, per MS docs
az role assignment create \
  --assignee-object-id "$AGC_PRINCIPAL_ID" --assignee-principal-type ServicePrincipal \
  --scope "$AGC_RG_SCOPE" \
  --role "AppGw for Containers Configuration Manager"

# Reader on the AGC association (subnet)
SUBNET_ID="/subscriptions/.../subnets/snet-agc"
az role assignment create \
  --assignee-object-id "$AGC_PRINCIPAL_ID" --assignee-principal-type ServicePrincipal \
  --scope "$SUBNET_ID" \
  --role "Network Contributor"
```

### 4. Annotate the controller ServiceAccount

```bash
CLIENT_ID=$(az identity show -g "$RG" -n "$AGC_IDENTITY_NAME" --query clientId -o tsv)

kubectl annotate serviceaccount alb-controller-sa \
  -n azure-alb-system \
  azure.workload.identity/client-id="$CLIENT_ID" \
  --overwrite

kubectl label serviceaccount alb-controller-sa \
  -n azure-alb-system \
  azure.workload.identity/use=true \
  --overwrite
```

### 5. Restart the controller to pick up the token

```bash
kubectl rollout restart deployment/alb-controller -n azure-alb-system
kubectl rollout status deployment/alb-controller -n azure-alb-system --timeout=120s
```

### 6. App workload Workload Identity (per app)

For each application that will receive traffic, repeat the federated credential pattern:

```bash
az identity federated-credential create \
  --name "<app>-fed" \
  --identity-name "<app-managed-identity>" \
  --resource-group "$RG" \
  --issuer "$OIDC_ISSUER" \
  --subject "system:serviceaccount:<ns>:<sa>" \
  --audience "api://AzureADTokenExchange"
```

Annotate the app's ServiceAccount with `azure.workload.identity/client-id` and label `azure.workload.identity/use=true`.

## Validation

- [ ] `kubectl logs -n azure-alb-system deployment/alb-controller --tail=50` shows no `AADSTS` errors.
- [ ] Controller log includes `Successfully registered with AGC resource <agc-id>`.
- [ ] `kubectl get pods -n azure-alb-system` all pods `Running`, no `CrashLoopBackOff`.
- [ ] No long-lived secrets exist in `azure-alb-system` (`kubectl get secret -n azure-alb-system` shows only ServiceAccount tokens).

## Rollback

```bash
az identity federated-credential delete \
  --name "alb-controller-fed" \
  --identity-name "$AGC_IDENTITY_NAME" \
  --resource-group "$RG" --yes

kubectl annotate serviceaccount alb-controller-sa -n azure-alb-system \
  azure.workload.identity/client-id-

# (optional) revert role assignments
az role assignment delete --assignee "$AGC_PRINCIPAL_ID" --scope "$AGC_RG_SCOPE" \
  --role "AppGw for Containers Configuration Manager"
```

## References

- [Workload Identity overview](https://learn.microsoft.com/azure/aks/workload-identity-overview) (accessed 2026-04-22)
- [ALB controller install with Workload Identity](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller) (accessed 2026-04-22)
