terraform {
  required_version = ">= 1.6.0"
}

module "agc" {
  source = "../../../infra/terraform/agc"
}

output "agc_id" {
  description = "AGC resource ID from the base AGC module."
  value       = module.agc.agc_id
}

output "agc_frontend_fqdn" {
  description = "AGC frontend FQDN from the base AGC module."
  value       = module.agc.agc_frontend_fqdn
}

output "agc_identity_client_id" {
  description = "AGC managed identity client ID from the base AGC module."
  value       = module.agc.agc_identity_client_id
}
