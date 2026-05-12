# AGC Regional Availability

*Not an official Microsoft product. Community migration toolkit. See LICENSE.*

---

Application Gateway for Containers (AGC) has reached general availability and is deployed across 23 Azure regions as of 2026-05-12.

Source: [Application Gateway for Containers overview, Supported regions](https://learn.microsoft.com/azure/application-gateway/for-containers/overview#supported-regions) (accessed 2026-05-12).

This is a snapshot. The MS Learn page is canonical. Verify before deployment.

## Regional support table

| Azure Region | AGC GA Status |
|---|---|
| Australia East | GA |
| Brazil South | GA |
| Canada Central | GA |
| Central India | GA |
| Central US | GA |
| East Asia | GA |
| East US | GA |
| East US 2 | GA |
| France Central | GA |
| Germany West Central | GA |
| Korea Central | GA |
| North Central US | GA |
| North Europe | GA |
| Norway East | GA |
| South Central US | GA |
| Southeast Asia | GA |
| Switzerland North | GA |
| UAE North | GA |
| UK South | GA |
| West Europe | GA |
| West US | GA |
| West US 2 | GA |
| West US 3 | GA |

## Regional requirements

AGC requires a delegated subnet with `Microsoft.ServiceNetworking/trafficControllers` delegation and Azure CNI networking (Kubenet is not supported). Source: [Application Gateway for Containers overview](https://learn.microsoft.com/azure/application-gateway/for-containers/overview) (accessed 2026-05-12).

## Private cluster considerations

As of 2026-04-22, AGC support for **private AKS clusters** is in preview in some regions and may have different availability or limitations. Refer to [ADR-003: AGC Private Cluster Preview Status Gate](./adr/ADR-003-agc-private-cluster-preview-gate.md) and the runbook phase [00: AGC Availability Prerequisites](./runbook/00-prereq-agc-availability.md) before proceeding with a private cluster deployment.

## References

- [Application Gateway for Containers overview](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview) — Microsoft Learn
- [ADR-003: AGC Private Cluster Preview Status Gate](./adr/ADR-003-agc-private-cluster-preview-gate.md)
