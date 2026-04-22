# AGC Base Infrastructure (Terraform)

Terraform module for provisioning Application Gateway for Containers (AGC) base resources using the azapi provider. This module creates the trafficController, a default frontend, and associates it with a delegated subnet.

## What This Module Does

Creates the following Azure resources:

- `Microsoft.ServiceNetworking/trafficControllers` (Application Gateway for Containers)
- `Microsoft.ServiceNetworking/trafficControllers/frontends` (default frontend)
- `Microsoft.ServiceNetworking/trafficControllers/associations` (subnet association)

## Prerequisites

1. **Delegated Subnet**: Caller must pre-create a subnet with delegation to `Microsoft.ServiceNetworking/trafficControllers`. Example:

   ```hcl
   resource "azurerm_subnet" "agc" {
     name                 = "agc-subnet"
     resource_group_name  = azurerm_resource_group.example.name
     virtual_network_name = azurerm_virtual_network.example.name
     address_prefixes     = ["10.0.1.0/24"]

     delegation {
       name = "agc-delegation"
       service_delegation {
         name = "Microsoft.ServiceNetworking/trafficControllers"
       }
     }
   }
   ```

2. **Managed Identity**: AGC requires a managed identity with appropriate RBAC. This module does not create the identity. Caller must provision it separately and assign roles (typically `Network Contributor` on the subnet).

3. **Region Support**: AGC is available in 23 regions. See `docs/agc-region-matrix.md` for the current list.

4. **Private Cluster Support**: As of 2026-04-22, AGC support for private AKS clusters is in preview. See `docs/runbook/00-prereq-agc-availability.md` and ADR-003 for details.

## Usage

```hcl
module "agc" {
  source = "./infra/terraform/agc"

  name                = "myagc"
  resource_group_name = azurerm_resource_group.example.name
  location            = "eastus"
  subnet_id           = azurerm_subnet.agc.id

  tags = {
    environment = "production"
    project     = "aks-migration"
  }
}

output "agc_frontend_fqdn" {
  value = module.agc.frontend_fqdn
}
```

## Outputs

See `infra/agc/outputs.schema.json` for the parity contract. This module exposes:

- `alb_id`: Azure resource ID of the trafficController
- `alb_name`: Name of the trafficController
- `frontend_id`: Azure resource ID of the default frontend
- `frontend_fqdn`: FQDN of the default frontend (used in Gateway API Gateway resources)
- `association_id`: Azure resource ID of the subnet association

## API Version

Uses `Microsoft.ServiceNetworking/trafficControllers@2023-11-01` (GA stable). This is the latest stable API version as of 2026-04-22. Reference: https://learn.microsoft.com/en-us/azure/templates/microsoft.servicenetworking/trafficcontrollers

## ALZ Corp Constraints

- No public IPs are created by this module. AGC uses internal load balancing by default when associated with a subnet.
- Subnet is BYO (bring-your-own). Caller passes `subnet_id`.
- Managed identity is BYO. Caller provisions and assigns RBAC separately.

## Validation

Run `terraform validate` to check syntax and schema compliance. This module has been validated against Terraform >= 1.9.0 and azapi ~> 2.2.0.

## Bicep Parity

A Bicep equivalent exists at `infra/bicep/agc/`. Both modules satisfy `infra/agc/outputs.schema.json` per ADR-002.
