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
  region      = "${var.region}"
  app_name    = "alf"
  common_name = "${data.terraform_remote_state.common.short_environment_identifier}"
  tags        = "${data.terraform_remote_state.common.common_tags}"
}

module "dynamodb-table" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//dynamodb-tables"
  table_name = "${local.common_name}-${local.app_name}-backups-tbl"
  tags       = "${local.tags}"
  hash_key   = "task"
}
