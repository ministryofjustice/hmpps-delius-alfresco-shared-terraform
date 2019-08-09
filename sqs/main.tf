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
### Getting the s3 details
#-------------------------------------------------------------
data "terraform_remote_state" "s3bucket" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/s3buckets/terraform.tfstate"
    region = "${var.region}"
  }
}

####################################################
# Locals
####################################################

locals {
  region          = "${var.region}"
  common_name     = "${data.terraform_remote_state.common.short_environment_identifier}-alf-backup-q"
  s3bucket_kms_id = "${data.terraform_remote_state.s3bucket.s3bucket_kms_id}"
  tags            = "${data.terraform_remote_state.common.common_tags}"
}

resource "aws_sqs_queue" "alf_queue" {
  name                              = "${local.common_name}"
  kms_master_key_id                 = "${local.s3bucket_kms_id}"
  kms_data_key_reuse_period_seconds = 300
  tags                              = "${merge(local.tags, map("Name", "${local.common_name}"))}"
}
