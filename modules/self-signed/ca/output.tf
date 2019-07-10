# key
output "self_signed_ca_private_key" {
  value     = "${module.ca_key.private_key}"
  sensitive = true
}

# ca cert
output "self_signed_ca_cert_pem" {
  value = "${module.ca_cert.cert_pem}"
}

## AWS PARAMETER STORE
output "self_signed_ca_ssm_cert_pem_name" {
  value = "${module.create_parameter_ca_cert.name}"
}
