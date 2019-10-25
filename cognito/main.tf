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
    key    = "alfresco/common/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting ACM Cert
#-------------------------------------------------------------
data "aws_acm_certificate" "cert" {
  domain      = "*.${local.external_domain}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

####################################################
# Locals
####################################################

locals {
  region          = "${var.region}"
  app_name        = "elk5auth"
  common_name     = "${data.terraform_remote_state.common.short_environment_identifier}-${local.app_name}"
  tags            = "${data.terraform_remote_state.common.common_tags}"
  certificate_arn = "${data.aws_acm_certificate.cert.arn}"
  external_domain = "${data.terraform_remote_state.common.external_domain}"
  pool_domain     = "${local.app_name}.${local.external_domain}"
  account_id      = "${data.terraform_remote_state.common.common_account_id}"
}
