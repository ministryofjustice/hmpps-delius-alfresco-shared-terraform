####################################################
# Self Signed CA
####################################################
# key
output "self_signed_ca_private_key" {
  value     = "${module.self_signed_ca.self_signed_ca_private_key}"
  sensitive = true
}

# ca cert
output "self_signed_ca_cert_pem" {
  value = "${module.self_signed_ca.self_signed_ca_cert_pem}"
}

## AWS PARAMETER STORE
output "self_signed_ca_ssm_cert_pem_name" {
  value = "${module.self_signed_ca.self_signed_ca_ssm_cert_pem_name}"
}

####################################################
# Self Signed Cert
####################################################
# key
output "self_signed_server_private_key" {
  value     = "${module.self_signed_cert.self_signed_server_private_key}"
  sensitive = true
}

# csr
output "self_signed_server_cert_request_pem" {
  value     = "${module.self_signed_cert.self_signed_server_cert_request_pem}"
  sensitive = true
}

# cert
output "self_signed_server_cert_pem" {
  value = "${module.self_signed_cert.self_signed_server_cert_pem}"
}

# iam server cert
output "self_signed_server_iam_server_certificate_name" {
  value = "${module.self_signed_cert.self_signed_server_iam_server_certificate_name}"
}

output "self_signed_server_iam_server_certificate_id" {
  value = "${module.self_signed_cert.self_signed_server_iam_server_certificate_id}"
}

output "self_signed_server_iam_server_certificate_arn" {
  value = "${module.self_signed_cert.self_signed_server_iam_server_certificate_arn}"
}

output "self_signed_server_iam_server_certificate_path" {
  value = "${module.self_signed_cert.self_signed_server_iam_server_certificate_path}"
}

## AWS PARAMETER STORE
output "self_signed_server_ssm_cert_pem_name" {
  value = "${module.self_signed_cert.self_signed_server_ssm_cert_pem_name}"
}

output "self_signed_server_ssm_private_key_name" {
  value = "${module.self_signed_cert.self_signed_server_ssm_private_key_name}"
}
