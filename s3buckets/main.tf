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

####################################################
# Locals
####################################################

locals {
  region            = "${var.region}"
  alfresco_app_name = "${data.terraform_remote_state.common.alfresco_app_name}"
  common_name       = "${data.terraform_remote_state.common.common_name}"
  tags              = "${data.terraform_remote_state.common.common_tags}"
}

####################################################
# S3 bucket - Application Specific
####################################################
module "s3bucket" {
  source                   = "../modules/s3bucket"
  common_name              = "${local.common_name}"
  tags                     = "${local.tags}"
  s3cloudtrail_policy_file = "${file("../policies/s3bucket/s3_cloudtrail_policy.json")}"
}

#-------------------------------------------
### S3 bucket for elasticsearch
#--------------------------------------------
module "s3_elasticsearch_bucket" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//s3bucket//s3bucket_without_policy"
  s3_bucket_name = "${local.common_name}-es"
  tags           = "${local.tags}"
}
