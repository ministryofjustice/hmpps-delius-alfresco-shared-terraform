terraform {
  # The configuration for this backend will be filled in by Terragrunt
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {
  }
}

####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################
#-------------------------------------------------------------
### Getting the common details
#-------------------------------------------------------------
data "terraform_remote_state" "common" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/common/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the S3bucket details
#-------------------------------------------------------------
data "terraform_remote_state" "s3bucket" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/s3buckets/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the ASG details
#-------------------------------------------------------------
data "terraform_remote_state" "asg" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/asg/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the rds details
#-------------------------------------------------------------
data "terraform_remote_state" "rds" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/database/terraform.tfstate"
    region = var.region
  }
}

####################################################
# Locals
####################################################

locals {
  region                       = var.region
  application                  = "logs-archive"
  common_name                  = data.terraform_remote_state.common.outputs.common_name
  function_name                = "${local.common_name}-${local.application}"
  tags                         = data.terraform_remote_state.common.outputs.common_tags
  config-bucket                = data.terraform_remote_state.common.outputs.common_s3-config-bucket
  logs_bucket_arn              = data.terraform_remote_state.s3bucket.outputs.cloudwatch_archive_bucket_arn
  logs_bucket_name             = data.terraform_remote_state.s3bucket.outputs.cloudwatch_archive_bucket_name
  lambda_function_payload_file = "./src/build/function.zip"
  kms_arn                      = data.terraform_remote_state.common.outputs.kms_arn
}

