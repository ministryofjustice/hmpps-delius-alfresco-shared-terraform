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
### Getting the common details
#-------------------------------------------------------------
data "terraform_remote_state" "common" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/common/terraform.tfstate"
    region = "${var.region}"
  }
}

####################################################
# Locals
####################################################
locals {
  tags = "${data.terraform_remote_state.common.common_tags}"

  subject = {
    common_name  = "ca.${data.terraform_remote_state.common.common_private_zone_name}"
    organization = "${var.environment_identifier}-${var.alfresco_app_name}"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

############################################
# CREATE TLS KEY
############################################
# CA KEY 
module "ca_key" {
  source    = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//tls//tls_private_key"
  algorithm = "${var.self_signed_ca_algorithm}"
  rsa_bits  = "${var.self_signed_ca_rsa_bits}"
}

############################################
# CREATE TLS CA CERT
############################################
# # CA CERT
module "ca_cert" {
  source                = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//tls//tls_self_signed_cert"
  key_algorithm         = "${var.self_signed_ca_algorithm}"
  private_key_pem       = "${module.ca_key.private_key}"
  subject               = ["${local.subject}"]
  validity_period_hours = "${var.self_signed_ca_validity_period_hours}"
  early_renewal_hours   = "${var.self_signed_ca_early_renewal_hours}"
  is_ca_certificate     = "${var.is_ca_certificate}"
  allowed_uses          = ["${local.allowed_uses}"]
}

############################################
# ADD TO SSM
############################################
# Add to SSM
module "create_parameter_ca_cert" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//ssm//parameter_store_file"
  parameter_name = "${var.environment_identifier}-${var.alfresco_app_name}-self-signed-ca-crt"
  description    = "${var.environment_identifier}-${var.alfresco_app_name}-self-signed-ca-crt"
  type           = "String"
  value          = "${module.ca_cert.cert_pem}"
  tags           = "${local.tags}"
}
