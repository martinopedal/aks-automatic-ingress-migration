module agc '../../../infra/bicep/agc/main.bicep' = {
  name: 'agc-base'
}

output agc_id string = agc.outputs.agc_id
output agc_frontend_fqdn string = agc.outputs.agc_frontend_fqdn
output agc_identity_client_id string = agc.outputs.agc_identity_client_id
