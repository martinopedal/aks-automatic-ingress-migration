# AGC Regional Availability

*Not an official Microsoft product. Community migration toolkit. See LICENSE.*

---

Application Gateway for Containers (AGC) has reached general availability and is deployed across multiple Azure regions. This page tracks regional availability as of the access date below.

**Source:** Microsoft Learn AGC overview page accessed 2026-05-12. When in doubt, check the authoritative source to confirm current availability before deployment.

## Regional support table

| Azure Region | AGC GA Status | Notes |
|---|---|---|
| East US | GA | Available |
| East US 2 | GA | Available |
| West US | GA | Available |
| West US 2 | GA | Available |
| West US 3 | GA | Available |
| Central US | GA | Available |
| North Central US | GA | Available |
| South Central US | GA | Available |
| Canada East | GA | Available |
| Canada Central | GA | Available |
| North Europe | GA | Available |
| West Europe | GA | Available |
| UK South | GA | Available |
| UK West | GA | Available |
| France Central | GA | Available |
| Germany West Central | GA | Available |
| Switzerland North | GA | Available |
| Sweden Central | GA | Available |
| Norway East | GA | Available |
| Southeast Asia | GA | Available |
| East Asia | GA | Available |
| Japan East | GA | Available |
| Australia East | GA | Available |

**Note:** AGC was available in 23+ Azure regions as of 2026-05. For the authoritative current list of supported regions, consult the [Application Gateway for Containers overview](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview) on Microsoft Learn.

## Regional requirements

AGC requires:

- Azure CNI networking (static or dynamic IP assignment). Kubenet is not supported.
- A delegated subnet with `Microsoft.ServiceNetworking/trafficControllers` delegation. Subnet size must be `/24` or larger.
- Appropriate RBAC on the subnet and AGC resource for the ALB controller managed identity.

## Private cluster considerations

As of 2026-04-22, AGC support for **private AKS clusters** is in preview in some regions and may have different availability or limitations. Refer to [ADR-003: AGC Private Cluster Preview Status Gate](./adr/ADR-003-agc-private-cluster-preview-gate.md) and the runbook phase [00: AGC Availability Prerequisites](./runbook/00-prereq-agc-availability.md) before proceeding with a private cluster deployment.

## References

- [Application Gateway for Containers overview](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview) — Microsoft Learn
- [ADR-003: AGC Private Cluster Preview Status Gate](./adr/ADR-003-agc-private-cluster-preview-gate.md)
