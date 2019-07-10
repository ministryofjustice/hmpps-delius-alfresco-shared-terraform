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
### Getting the S3bucket details
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
### Getting the Dynamodb details
#-------------------------------------------------------------
data "terraform_remote_state" "dynamodb" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/dynamodb/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the Dynamodb details
#-------------------------------------------------------------
data "terraform_remote_state" "mon" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "shared-monitoring/terraform.tfstate"
    region = "${var.region}"
  }
}

####################################################
# Locals
####################################################

locals {
  region                     = "${var.region}"
  alfresco_app_name          = "${data.terraform_remote_state.common.alfresco_app_name}"
  common_name                = "${data.terraform_remote_state.common.common_name}"
  tags                       = "${data.terraform_remote_state.common.common_tags}"
  alfresco-storage_s3bucket  = "${data.terraform_remote_state.s3bucket.s3bucket}"
  config-bucket              = "${data.terraform_remote_state.common.common_s3-config-bucket}"
  monitoring_bucket_arn      = "${data.terraform_remote_state.mon.monitoring_server_bucket_arn}"
  monitoring_bucket_name     = "${data.terraform_remote_state.mon.monitoring_server_bucket_name}"
  remote_config_bucket       = "${data.terraform_remote_state.common.remote_config_bucket}"
  elasticsearch_bucket       = "${data.terraform_remote_state.s3bucket.s3_elasticsearch_bucket}"
  remote_iam_role            = "${data.terraform_remote_state.common.remote_iam_role}"
  alfresco_kms_arn           = "${data.terraform_remote_state.s3bucket.s3bucket_kms_arn}"
  restore_dynamodb_table_arn = "${data.terraform_remote_state.dynamodb.dynamodb_table_arn}"
  vpc_cidr                   = "${data.terraform_remote_state.common.vpc_cidr_block}"
  monitoring_kms_arn         = "${data.terraform_remote_state.mon.monitoring_kms_arn}"
}

####################################################
# IAM - Application Specific
####################################################
module "iam" {
  source                     = "../modules/iam"
  common_name                = "${local.common_name}"
  tags                       = "${local.tags}"
  ec2_role_policy_file       = "${file("../policies/ec2_role_policy.json")}"
  ecs_role_policy_file       = "${file("../policies/ecs_role_policy.json")}"
  ec2_policy_file            = "ec2_policy.json"
  ecs_policy_file            = "ecs_policy.json"
  ec2_internal_policy_file   = "${file("../policies/ec2_internal_policy.json")}"
  remote_iam_role            = "${local.remote_iam_role}"
  remote_config_bucket       = "${local.remote_config_bucket}"
  storage_s3bucket           = "${local.alfresco-storage_s3bucket}"
  s3-config-bucket           = "${local.config-bucket}"
  s3bucket_kms_arn           = "${local.alfresco_kms_arn}"
  restore_dynamodb_table_arn = "${local.restore_dynamodb_table_arn}"
}
