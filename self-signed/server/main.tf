####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

locals {
  tags        = "${var.tags}"
  common_name = "${var.common_name}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]

  dns_names = ["*.${var.internal_domain}"]

  subject = {
    common_name  = "${var.internal_domain}"
    organization = "${var.common_name}"
  }

  ca_cert_pem     = "${var.ca_cert_pem}"
  internal_domain = "${var.internal_domain}"
}

############################################
# ADD TO KEY AND CSR
############################################
# KEY 
module "server_key" {
  source    = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//tls//tls_private_key"
  algorithm = "${var.self_signed_server_algorithm}"
  rsa_bits  = "${var.self_signed_server_rsa_bits}"
}

# csr
module "server_csr" {
  source          = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//tls//tls_cert_request"
  key_algorithm   = "${var.self_signed_server_algorithm}"
  private_key_pem = "${module.server_key.private_key}"
  subject         = ["${local.subject}"]
  dns_names       = ["${local.dns_names}"]
}

############################################
# SIGN CERT
############################################
# cert
module "server_cert" {
  source                = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//tls//tls_locally_signed_cert"
  cert_request_pem      = "${module.server_csr.cert_request_pem}"
  ca_key_algorithm      = "${var.self_signed_server_algorithm}"
  ca_private_key_pem    = "${var.ca_private_key_pem}"
  ca_cert_pem           = "${local.ca_cert_pem}"
  validity_period_hours = "${var.self_signed_server_validity_period_hours}"
  early_renewal_hours   = "${var.self_signed_server_early_renewal_hours}"

  allowed_uses = ["${local.allowed_uses}"]
}

############################################
# ADD TO IAM
############################################
# upload to IAM
module "iam_server_certificate" {
  source            = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam_certificate"
  name_prefix       = "${local.internal_domain}-cert"
  certificate_body  = "${module.server_cert.cert_pem}"
  private_key       = "${module.server_key.private_key}"
  certificate_chain = "${local.ca_cert_pem}"
  path              = "/${var.environment_identifier}/"
}

############################################
# ADD TO SSM
############################################
# CERT
module "create_parameter_cert" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//ssm//parameter_store_file"
  parameter_name = "${local.common_name}-self-signed-crt"
  description    = "${local.common_name}-self-signed-crt"
  type           = "String"
  value          = "${module.server_cert.cert_pem}"
  tags           = "${local.tags}"
}

module "create_parameter_key" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//ssm//parameter_store_file"
  parameter_name = "${local.common_name}-self-signed-private-key"
  description    = "${local.common_name}-self-signed-private-key"
  type           = "SecureString"
  value          = "${module.server_key.private_key}"
  tags           = "${local.tags}"
}
