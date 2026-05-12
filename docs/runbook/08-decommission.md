# Phase 08, decommission ingress-nginx and the App Routing addon

## Goal

Remove the legacy ingress controller, the App Routing addon (if used), and any orphaned resources. Lock the cluster against accidental ingress-nginx reinstall.

## Prerequisites

- Phase 07 cutover at 100% AGC for **at least 7 days** with no incidents.
- All Ingress objects removed from the cluster (or annotated for archival).
- Stakeholders notified.
- A point-in-time **etcd backup** exists. AKS Automatic snapshots etcd; confirm with platform team.

## Steps

### 1. Inventory remaining Ingress objects

```bash
kubectl get ingress -A
```

There should be none. If any remain, return to Phase 04.

### 2. Disable the App Routing addon (if enabled)

```bash
az aks approuting disable -g <rg> -n <cluster> --yes
```

This removes the addon-managed `app-routing-system` namespace and the addon's controller.

### 3. Uninstall manually-installed ingress-nginx (if Helm)

```bash
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx --wait=true
```

If installed via Kustomize or raw YAML:

```bash
kubectl delete -f <original-manifest-path>
```

### 4. Clean up the IngressClass

```bash
kubectl delete ingressclass nginx --ignore-not-found
kubectl delete ingressclass webapprouting.kubernetes.azure.com --ignore-not-found
```

### 5. Remove orphaned LoadBalancer Services

If the App Routing addon or your Helm install created `LoadBalancer` Services with public IPs, those Azure Public IPs may still exist:

```bash
az network public-ip list -g MC_<rg>_<cluster>_<region> -o table
```

Delete any tied to the removed Services. Be careful: AKS Automatic uses `MC_*` resource groups and other addons may also have IPs there.

### 6. Lock against reinstall (Gatekeeper / Kyverno)

Add a policy that rejects creation of any `Ingress` resource cluster-wide, forcing developers to use `HTTPRoute`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: deny-legacy-ingress
spec:
  validationFailureAction: Enforce
  rules:
    - name: deny-ingress
      match:
        any:
          - resources:
              kinds: ["Ingress"]
      validate:
        message: "Use HTTPRoute (Gateway API) instead of Ingress. See docs/runbook/."
        deny: {}
```

Apply:

```bash
kubectl apply -f cluster-policy/deny-legacy-ingress.yaml
```

### 7. Update internal docs and golden paths

- Remove ingress-nginx samples from internal templates.
- Update CI scaffolding (Backstage, etc.) to generate `HTTPRoute` not `Ingress`.
- Archive the assessment.json from Phase 01 to your knowledge base.

## Validation

- [ ] `kubectl get ingress -A` returns `No resources found`.
- [ ] `kubectl get ingressclass` does not include `nginx` or `webapprouting.kubernetes.azure.com`.
- [ ] `az aks show -g <rg> -n <cluster> --query ingressProfile.webAppRouting.enabled` returns `false`.
- [ ] No `LoadBalancer` Services remain that were owned by the legacy controller.
- [ ] Kyverno or Gatekeeper policy is `Enforce` and rejects a test `Ingress` apply.

## Rollback

Re-enable App Routing:

```bash
az aks approuting enable -g <rg> -n <cluster>
```

Or reinstall ingress-nginx via Helm. **However**, after this phase your Ingress YAMLs no longer exist in the cluster. You would need to re-apply them from version control. Production traffic is on AGC, so the rollback path is to flip DNS back (Phase 07 rollback) **before** Phase 08, not after.

## References

- [App Routing addon disable](https://learn.microsoft.com/azure/aks/app-routing#enable-or-disable-the-app-routing-addon) (accessed 2026-04-22)
- [Kyverno cluster policies](https://kyverno.io/docs/writing-policies/) (accessed 2026-04-22)
