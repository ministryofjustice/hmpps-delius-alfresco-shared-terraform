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
### Getting the IAM details
#-------------------------------------------------------------
data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/iam/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the s3 details
#-------------------------------------------------------------
data "terraform_remote_state" "s3bucket" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/s3buckets/terraform.tfstate"
    region = var.region
  }
}

####################################################
# Locals
####################################################

locals {
  region              = var.region
  application         = data.terraform_remote_state.common.outputs.alfresco_app_name
  common_name         = "${data.terraform_remote_state.common.outputs.short_environment_identifier}-${local.application}"
  tags                = data.terraform_remote_state.common.outputs.common_tags
  config-bucket       = data.terraform_remote_state.common.outputs.common_s3-config-bucket
  account_id          = data.terraform_remote_state.common.outputs.common_account_id
  iam_role_arn        = data.terraform_remote_state.iam.outputs.iam_instance_es_admin_role_arn
  s3bucket            = data.terraform_remote_state.s3bucket.outputs.s3bucket
  function_worker     = "${local.common_name}-restore-docs-worker"
  function_submitter  = "${local.common_name}-restore-docs-submit"
  logs_worker         = "/aws/lambda/${local.function_worker}"
  logs_submit         = "/aws/lambda/${local.function_submitter}"
  worker_payload_file = "../../functions/s3RestoreWorker/function.zip"
  submit_payload_file = "../../functions/s3RestoreSubmit/function.zip"
}

