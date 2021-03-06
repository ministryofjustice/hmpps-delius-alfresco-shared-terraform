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

####################################################
# Locals
####################################################

locals {
  region             = var.region
  alfresco_app_name  = data.terraform_remote_state.common.outputs.alfresco_app_name
  common_name        = data.terraform_remote_state.common.outputs.common_name
  tags               = data.terraform_remote_state.common.outputs.common_tags
  alf_backups_config = merge(var.alf_backups_config, var.alf_backups_map)
  transition_days    = local.alf_backups_config["transition_days"]
  expiration_days    = local.alf_backups_config["expiration_days"]
}

####################################################
# S3 bucket - Application Specific
####################################################
module "s3bucket" {
  source                   = "../modules/s3bucket"
  common_name              = local.common_name
  tags                     = local.tags
  s3cloudtrail_policy_file = file("../policies/s3bucket/s3_cloudtrail_policy.json")
  s3_lifecycle_config      = var.alf_backups_config
  kms_policy_template      = var.environment_type == "prod" ? "policies/kms-policy-cross-account.json" : "policies/kms-policy.json"
}

