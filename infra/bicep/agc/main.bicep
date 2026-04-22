// Application Gateway for Containers base resources (Bicep)
// API version: Microsoft.ServiceNetworking/trafficControllers@2023-11-01 (GA stable)
// Reference: https://learn.microsoft.com/en-us/azure/templates/microsoft.servicenetworking/trafficcontrollers
//
// Prerequisites:
// - Subnet with delegation to Microsoft.ServiceNetworking/trafficControllers (passed via subnetId)
// - AGC managed identity with appropriate RBAC (created/assigned by caller, not this module)
//
// ADR-003 note: Private AKS cluster support for AGC is in preview as of 2026-04-22.
// This module does not enforce or check preview status. See docs/runbook/00-prereq-agc-availability.md.

@description('Name of the Application Gateway for Containers (trafficController). Must match pattern ^[A-Za-z0-9]([A-Za-z0-9-_.]{0,62}[A-Za-z0-9])?$')
@minLength(1)
@maxLength(64)
param name string

@description('Azure region for AGC resources. Must be one of the 23 AGC-supported regions. See docs/agc-region-matrix.md')
param location string = resourceGroup().location

@description('Azure resource ID of the subnet delegated to Microsoft.ServiceNetworking/trafficControllers. Caller must pre-create subnet with delegation.')
param subnetId string

@description('Tags to apply to AGC resources')
param tags object = {}

// Application Gateway for Containers (trafficController)
resource alb 'Microsoft.ServiceNetworking/trafficControllers@2023-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {}
}

// Frontend for the trafficController
resource frontend 'Microsoft.ServiceNetworking/trafficControllers/frontends@2023-11-01' = {
  parent: alb
  name: '${name}-frontend'
  location: location
  tags: tags
  properties: {}
}

// Association between trafficController and delegated subnet
resource association 'Microsoft.ServiceNetworking/trafficControllers/associations@2023-11-01' = {
  parent: alb
  name: '${name}-association'
  location: location
  tags: tags
  properties: {
    associationType: 'subnets'
    subnet: {
      id: subnetId
    }
  }
}

// Outputs must match infra/agc/outputs.schema.json per ADR-002

@description('Azure resource ID of the Application Gateway for Containers (trafficController)')
output alb_id string = alb.id

@description('Name of the Application Gateway for Containers resource')
output alb_name string = alb.name

@description('Azure resource ID of the AGC frontend')
output frontend_id string = frontend.id

@description('Fully qualified domain name of the AGC frontend')
output frontend_fqdn string = frontend.properties.fqdn

@description('Azure resource ID of the subnet association to the trafficController')
output association_id string = association.id
