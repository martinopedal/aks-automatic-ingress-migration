# Quickstart: Gateway API on AKS Automatic

*Not an official Microsoft product. Community migration toolkit. See LICENSE.*

Get a single HTTP workload running on Gateway API and Application Gateway for Containers in under 10 minutes. No TLS, no Workload Identity, no ALZ Corp wiring. This is a smoke test, not a production blueprint.

For production setup, read `docs/runbook/`.

## Prerequisites

- AKS cluster on a [supported Kubernetes version](https://learn.microsoft.com/azure/aks/supported-kubernetes-versions)
- Subnet delegated to `Microsoft.ServiceNetworking/trafficControllers` (per [AGC overview](https://learn.microsoft.com/azure/application-gateway/for-containers/overview))
- AGC ALB controller installed in the cluster (`azure-alb-system` namespace via [Helm install](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller))
- `kubectl` access to the cluster
- Terraform or Azure CLI

> **AKS Automatic users:** Per the [AGC FAQ](https://learn.microsoft.com/azure/application-gateway/for-containers/faq), the Helm-installed ALB Controller is unsupported on AKS Automatic. Automatic clusters must use the [AGC ALB Controller AKS add-on (preview)](https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller-addon), which installs the controller into `kube-system` instead. See [`docs/preview-features.md`](../../docs/preview-features.md) for the trade-offs.

## 1. Provision AGC

```bash
cd examples/quickstart/infra
terraform init
terraform plan
terraform apply
```

Note the `frontend_fqdn` output. You will test against this endpoint.

## 2. Deploy workload and Gateway

```bash
kubectl apply -k examples/quickstart/manifests/
```

This creates:
- Namespace `quickstart`
- Deployment with `nginxinc/nginx-unprivileged:latest`
- ClusterIP Service
- Gateway (HTTP :80, `azure-alb-external` gatewayClassName)
- HTTPRoute pointing to the Service

## 3. Test traffic

Get the AGC frontend FQDN from Terraform outputs:

```bash
cd examples/quickstart/infra
terraform output -raw frontend_fqdn
```

Test from a machine that can reach the AGC frontend:

```bash
curl -sS http://<frontend_fqdn>/
```

Expected response: nginx default page HTML.

## 4. Cleanup

```bash
kubectl delete -k examples/quickstart/manifests/
cd examples/quickstart/infra
terraform destroy
```

## What this example excludes

Decision #1 defines quickstart scope. Excluded:
- HTTPS/TLS (covered in catalog samples)
- NetworkPolicy (Sentinel's domain)
- ALZ Corp wiring (documented in `docs/runbook/`)
- Workload Identity (not needed for smoke test)
- Multiple routes, path rewrites, header manipulation (covered in `manifests/ingress-to-gateway/`)

## References

- Gateway API spec: https://gateway-api.sigs.k8s.io/
- AGC documentation: https://learn.microsoft.com/azure/application-gateway/for-containers/
- AKS Automatic: https://learn.microsoft.com/azure/aks/intro-aks-automatic
- AGC FAQ (AKS Automatic constraint): https://learn.microsoft.com/azure/application-gateway/for-containers/faq
