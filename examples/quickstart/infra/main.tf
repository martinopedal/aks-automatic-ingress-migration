# Quickstart infrastructure wrapper for Application Gateway for Containers
#
# This Terraform configuration calls the shared AGC module from infra/terraform/agc.
# For production use, see docs/runbook/ and examples/hello-world/.

terraform {
  required_version = ">= 1.9"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azapi" {}

# Variables with defaults for quickstart smoke test
variable "resource_group_name" {
  type        = string
  description = "Azure resource group name where AGC will be created"
}

variable "subnet_id" {
  type        = string
  description = "Azure resource ID of subnet delegated to Microsoft.ServiceNetworking/trafficControllers"
}

variable "name" {
  type        = string
  description = "Name for the AGC traffic controller"
  default     = "quickstart-agc"
}

variable "location" {
  type        = string
  description = "Azure region. If null, defaults to resource group location."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags for AGC resources"
  default = {
    environment = "quickstart"
    repo        = "aks-automatic-ingress-migration"
  }
}

# Call shared AGC module
module "agc" {
  source = "../../../infra/terraform/agc"

  name                = var.name
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  location            = var.location
  tags                = var.tags
}

# Outputs for kubectl testing and validation
output "alb_id" {
  description = "Azure resource ID of the Application Gateway for Containers"
  value       = module.agc.alb_id
}

output "alb_name" {
  description = "Name of the AGC traffic controller"
  value       = module.agc.alb_name
}

output "frontend_id" {
  description = "Azure resource ID of the AGC frontend"
  value       = module.agc.frontend_id
}

output "frontend_fqdn" {
  description = "Fully qualified domain name of the AGC frontend. Use this for curl testing."
  value       = module.agc.frontend_fqdn
}

output "association_id" {
  description = "Azure resource ID of the subnet association"
  value       = module.agc.association_id
}
