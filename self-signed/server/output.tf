# key
output "self_signed_server_private_key" {
  value     = "${module.server_key.private_key}"
  sensitive = true
}

# csr
output "self_signed_server_cert_request_pem" {
  value     = "${module.server_csr.cert_request_pem}"
  sensitive = true
}

# cert
output "self_signed_server_cert_pem" {
  value = "${module.server_cert.cert_pem}"
}

# iam server cert
output "self_signed_server_iam_server_certificate_name" {
  value = "${module.iam_server_certificate.name}"
}

output "self_signed_server_iam_server_certificate_id" {
  value = "${module.iam_server_certificate.id}"
}

output "self_signed_server_iam_server_certificate_arn" {
  value = "${module.iam_server_certificate.arn}"
}

output "self_signed_server_iam_server_certificate_path" {
  value = "${module.iam_server_certificate.path}"
}

## AWS PARAMETER STORE
output "self_signed_server_ssm_cert_pem_name" {
  value = "${module.create_parameter_cert.name}"
}

output "self_signed_server_ssm_private_key_name" {
  value = "${module.create_parameter_key.name}"
}
