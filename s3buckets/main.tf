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
  region                 = "${var.region}"
  alfresco_app_name      = "${data.terraform_remote_state.common.alfresco_app_name}"
  environment_identifier = "${data.terraform_remote_state.common.environment_identifier}"
  tags                   = "${data.terraform_remote_state.common.common_tags}"
}

####################################################
# S3 bucket - Application Specific
####################################################
module "s3bucket" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=issue-62//projects//alfresco//s3bucket"
  alfresco_app_name        = "${local.alfresco_app_name}"
  environment_identifier   = "${local.environment_identifier}"
  tags                     = "${local.tags}"
  s3cloudtrail_policy_file = "${file("../policies/s3bucket/s3_cloudtrail_policy.json")}"
}
