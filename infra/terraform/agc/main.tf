# Application Gateway for Containers base resources
# Uses azapi provider for Microsoft.ServiceNetworking/trafficControllers (API 2023-11-01 GA)
# Reference: https://learn.microsoft.com/en-us/azure/templates/microsoft.servicenetworking/trafficcontrollers
#
# Prerequisites:
# - Subnet with delegation to Microsoft.ServiceNetworking/trafficControllers (passed via subnet_id)
# - AGC managed identity with appropriate RBAC (created/assigned by caller, not this module)
#
# ADR-003 note: Private AKS cluster support for AGC is in preview as of 2026-04-22.
# This module does not enforce or check preview status. See docs/runbook/00-prereq-agc-availability.md.

data "azapi_resource" "resource_group" {
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  name      = var.resource_group_name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
}

data "azapi_client_config" "current" {}

# Application Gateway for Containers (trafficController)
resource "azapi_resource" "alb" {
  type      = "Microsoft.ServiceNetworking/trafficControllers@2023-11-01"
  name      = var.name
  location  = var.location
  parent_id = data.azapi_resource.resource_group.id

  body = {
    properties = {}
  }

  tags = var.tags
}

# Frontend for the trafficController
resource "azapi_resource" "frontend" {
  type      = "Microsoft.ServiceNetworking/trafficControllers/frontends@2023-11-01"
  name      = "${var.name}-frontend"
  location  = var.location
  parent_id = azapi_resource.alb.id

  body = {
    properties = {}
  }

  tags = var.tags
}

# Association between trafficController and delegated subnet
resource "azapi_resource" "association" {
  type      = "Microsoft.ServiceNetworking/trafficControllers/associations@2023-11-01"
  name      = "${var.name}-association"
  location  = var.location
  parent_id = azapi_resource.alb.id

  body = {
    properties = {
      associationType = "subnets"
      subnet = {
        id = var.subnet_id
      }
    }
  }

  tags = var.tags
}
