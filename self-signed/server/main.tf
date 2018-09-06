terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.16"
}

####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

#-------------------------------------------------------------
### Getting the current vpc
#-------------------------------------------------------------
data "terraform_remote_state" "common" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/common/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the ca
#-------------------------------------------------------------
data "terraform_remote_state" "ca" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/self-signed/ca/terraform.tfstate"
    region = "${var.region}"
  }
}

locals {
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]

  dns_names = ["*.${data.terraform_remote_state.common.common_private_zone_name}"]

  subject = {
    common_name  = "${data.terraform_remote_state.common.common_private_zone_name}"
    organization = "${var.environment_identifier}-${var.alfresco_app_name}"
  }
  tags = "${data.terraform_remote_state.common.common_tags}"
}

############################################
# ADD TO KEY AND CSR
############################################
# KEY 
module "server_key" {
  source    = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//tls//tls_private_key"
  algorithm = "${var.self_signed_server_algorithm}"
  rsa_bits  = "${var.self_signed_server_rsa_bits}"
}

# csr
module "server_csr" {
  source          = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//tls//tls_cert_request"
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
  source             = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//tls//tls_locally_signed_cert"
  cert_request_pem   = "${module.server_csr.cert_request_pem}"
  ca_key_algorithm   = "${var.self_signed_server_algorithm}"
  ca_private_key_pem = "${data.terraform_remote_state.ca.self_signed_ca_private_key}"
  ca_cert_pem        = "${data.terraform_remote_state.ca.self_signed_ca_cert_pem}"

  validity_period_hours = "${var.self_signed_server_validity_period_hours}"
  early_renewal_hours   = "${var.self_signed_server_early_renewal_hours}"

  allowed_uses = ["${local.allowed_uses}"]
}

############################################
# ADD TO IAM
############################################
# upload to IAM
module "iam_server_certificate" {
  source            = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//iam_certificate"
  name_prefix       = "${data.terraform_remote_state.common.common_private_zone_name}-cert"
  certificate_body  = "${module.server_cert.cert_pem}"
  private_key       = "${module.server_key.private_key}"
  certificate_chain = "${data.terraform_remote_state.ca.self_signed_ca_cert_pem}"
  path              = "/${var.environment_identifier}/"
}

############################################
# ADD TO SSM
############################################
# CERT
module "create_parameter_cert" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//ssm//parameter_store_file"
  parameter_name = "${var.environment_identifier}-${var.alfresco_app_name}-self-signed-crt"
  description    = "${var.environment_identifier}-${var.alfresco_app_name}-self-signed-crt"
  type           = "String"
  value          = "${module.server_cert.cert_pem}"
  tags           = "${local.tags}"
}

module "create_parameter_key" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//ssm//parameter_store_file"
  parameter_name = "${var.environment_identifier}-${var.alfresco_app_name}-self-signed-private-key"
  description    = "${var.environment_identifier}-${var.alfresco_app_name}-self-signed-private-key"
  type           = "SecureString"
  value          = "${module.server_key.private_key}"
  tags           = "${local.tags}"
}
