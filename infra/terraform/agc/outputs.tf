# Outputs must match infra/agc/outputs.schema.json per ADR-002

output "alb_id" {
  description = "Azure resource ID of the Application Gateway for Containers (trafficController)"
  value       = azapi_resource.alb.id
}

output "alb_name" {
  description = "Name of the Application Gateway for Containers resource"
  value       = azapi_resource.alb.name
}

output "frontend_id" {
  description = "Azure resource ID of the AGC frontend"
  value       = azapi_resource.frontend.id
}

output "frontend_fqdn" {
  description = "Fully qualified domain name of the AGC frontend"
  value       = jsondecode(azapi_resource.frontend.output).properties.fqdn
}

output "association_id" {
  description = "Azure resource ID of the subnet association to the trafficController"
  value       = azapi_resource.association.id
}
