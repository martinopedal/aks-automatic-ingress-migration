# Terraform and provider version constraints for AGC module
# API version: Microsoft.ServiceNetworking/trafficControllers@2023-11-01 (GA stable)
# Reference: https://learn.microsoft.com/en-us/azure/templates/microsoft.servicenetworking/trafficcontrollers

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    # azapi required for Microsoft.ServiceNetworking resources
    # AGC support is stable in azapi as of 2.0.0
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.2.0"
    }
  }
}
