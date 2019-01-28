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

#-------------------------------------------------------------
### Getting the security groups details
#-------------------------------------------------------------
data "terraform_remote_state" "security-groups" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/security-groups/terraform.tfstate"
    region = "${var.region}"
  }
}

####################################################
# Locals
####################################################

locals {
  account_id                   = "${data.terraform_remote_state.common.common_account_id}"
  vpc_id                       = "${data.terraform_remote_state.common.vpc_id}"
  internal_domain              = "${data.terraform_remote_state.common.internal_domain}"
  private_zone_id              = "${data.terraform_remote_state.common.private_zone_id}"
  public_zone_id               = "${data.terraform_remote_state.common.public_zone_id}"
  external_domain              = "${data.terraform_remote_state.common.external_domain}"
  environment_identifier       = "${data.terraform_remote_state.common.environment_identifier}"
  common_name                  = "${data.terraform_remote_state.common.common_name}"
  short_environment_identifier = "${data.terraform_remote_state.common.short_environment_identifier}"
  region                       = "${var.region}"
  alfresco_app_name            = "${data.terraform_remote_state.common.alfresco_app_name}"
  environment                  = "${data.terraform_remote_state.common.environment}"
  tags                         = "${data.terraform_remote_state.common.common_tags}"
  s3bucket_kms_arn             = "${data.terraform_remote_state.s3bucket.s3bucket_kms_arn}"
  private_subnet_ids           = ["${data.terraform_remote_state.common.private_subnet_ids}"]

  security_groups = [
    "${data.terraform_remote_state.security-groups.security_groups_sg_efs_sg_id}",
  ]
}

####################################################
# EFS content
####################################################
module "efs_content" {
  source                 = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=issue-113//modules//efs"
  environment_identifier = "${local.environment_identifier}"
  tags                   = "${local.tags}"
  encrypted              = true
  kms_key_id             = "${local.s3bucket_kms_arn}"
  performance_mode       = "generalPurpose"
  throughput_mode        = "bursting"
  share_name             = "content_store"
  zone_id                = "${local.private_zone_id}"
  domain                 = "${local.internal_domain}"
  subnets                = "${local.private_subnet_ids}"
  security_groups        = ["${local.security_groups}"]
}

####################################################
# EFS content_deleted
####################################################
module "efs_content_deleted" {
  source                 = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=issue-113//modules//efs"
  environment_identifier = "${local.environment_identifier}"
  tags                   = "${local.tags}"
  encrypted              = true
  kms_key_id             = "${local.s3bucket_kms_arn}"
  performance_mode       = "generalPurpose"
  throughput_mode        = "bursting"
  share_name             = "content_store_deleted"
  zone_id                = "${local.private_zone_id}"
  domain                 = "${local.internal_domain}"
  subnets                = "${local.private_subnet_ids}"
  security_groups        = ["${local.security_groups}"]
}
