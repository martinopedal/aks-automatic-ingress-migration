# Identity wiring for AGC controller (Workload Identity)

Owner: Iris

This runbook wires the AGC ALB controller to a user-assigned managed identity using AKS Workload Identity and federated credentials, avoiding service principal secrets in cluster.

## Inputs

- `SUBSCRIPTION_ID`
- `RESOURCE_GROUP`
- `AKS_NAME`
- `MI_RESOURCE_GROUP`
- `MI_NAME`
- `AGC_RESOURCE_ID`
- `K8S_NAMESPACE` (for example `azure-alb-system`)
- `K8S_SERVICE_ACCOUNT` (for example `alb-controller-sa`)

## 1) Read-only precheck

```bash
az account show --query "{subscriptionId:id, tenantId:tenantId}" -o table
az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" \
  --query "{oidc:oidcIssuerProfile.issuerUrl, workloadIdentity:securityProfile.workloadIdentity.enabled}" -o yaml
kubectl get serviceaccount -n "$K8S_NAMESPACE" "$K8S_SERVICE_ACCOUNT" -o yaml
```

If OIDC issuer or Workload Identity is not enabled, stop and enable both before continuing.

## 2) Federation pattern selection

All patterns use:

- issuer = AKS OIDC issuer URL
- subject = `system:serviceaccount:<namespace>:<service-account>`
- audience = `api://AzureADTokenExchange`

Choose one:

1. **Strict isolation (default).** One managed identity per controller instance, one federated credential per service account.
2. **Shared identity across clusters.** Same managed identity, one federated credential per cluster and service account pair.
3. **Blue/green controller rollout.** Keep old and new service accounts active with separate federated credentials until cutover completes.

## 3) Create or update federated credential

```bash
OIDC_ISSUER="$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" --query "oidcIssuerProfile.issuerUrl" -o tsv)"
SUBJECT="system:serviceaccount:${K8S_NAMESPACE}:${K8S_SERVICE_ACCOUNT}"

az identity federated-credential create \
  --resource-group "$MI_RESOURCE_GROUP" \
  --identity-name "$MI_NAME" \
  --name "${AKS_NAME}-${K8S_NAMESPACE}-${K8S_SERVICE_ACCOUNT}" \
  --issuer "$OIDC_ISSUER" \
  --subject "$SUBJECT" \
  --audiences "api://AzureADTokenExchange"
```

## 4) Bind Kubernetes service account to managed identity

```bash
CLIENT_ID="$(az identity show -g "$MI_RESOURCE_GROUP" -n "$MI_NAME" --query "clientId" -o tsv)"
kubectl annotate serviceaccount -n "$K8S_NAMESPACE" "$K8S_SERVICE_ACCOUNT" \
  azure.workload.identity/client-id="$CLIENT_ID" --overwrite
```

## 5) Scope RBAC to AGC resource only

Assign only the minimum role required by the AGC ALB controller, scoped to `$AGC_RESOURCE_ID`. Do not grant subscription-wide rights.

```bash
PRINCIPAL_ID="$(az identity show -g "$MI_RESOURCE_GROUP" -n "$MI_NAME" --query "principalId" -o tsv)"
echo "principalId=$PRINCIPAL_ID"
echo "scope=$AGC_RESOURCE_ID"
```

Use the AGC ALB controller setup documentation to select the exact role for your deployment mode: [AGC ALB controller quickstart with Helm](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-helm) and [AGC ALB controller quickstart with AKS add-on](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon).

## 6) Validate token flow and controller health

```bash
kubectl get pods -n "$K8S_NAMESPACE" -l app.kubernetes.io/name=alb-controller
kubectl logs -n "$K8S_NAMESPACE" deploy/alb-controller --tail=200
```

The label and deployment name `alb-controller` follow the Microsoft AGC controller quickstart conventions.

Expected state:

- Controller pod starts without identity bootstrap errors.
- Controller can read and reconcile AGC resources.

## 7) Rollback

If validation fails:

1. Remove service account annotation.
2. Remove the new federated credential.
3. Reapply previous controller identity configuration.

## References

- [Use Microsoft Entra Workload ID with AKS](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview)
- [Deploy and configure Workload Identity on AKS](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster)
- [Workload identity federation concepts in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)
- [AGC ALB controller quickstart with Helm](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-helm)
- [AGC ALB controller quickstart with AKS add-on](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon)
