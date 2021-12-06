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

resource "random_id" "id" {
  byte_length = 8
}

####################################################
# Locals
####################################################

locals {
  alfresco_activemq_props = merge(var.alfresco_activemq_props, var.alfresco_activemq_configs)
  account_id              = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id                  = data.terraform_remote_state.common.outputs.vpc_id
  internal_domain         = data.terraform_remote_state.common.outputs.internal_domain
  private_zone_id         = data.terraform_remote_state.common.outputs.private_zone_id
  public_zone_id          = data.terraform_remote_state.common.outputs.public_zone_id
  external_domain         = data.terraform_remote_state.common.outputs.external_domain
  environment_identifier  = data.terraform_remote_state.common.outputs.environment_identifier
  common_name             = format("%s-alf-activeMQ-svc", data.terraform_remote_state.common.outputs.short_environment_identifier)
  region                  = var.region
  alfresco_app_name       = data.terraform_remote_state.common.outputs.alfresco_app_name
  environment             = data.terraform_remote_state.common.outputs.environment
  tags                    = data.terraform_remote_state.common.outputs.common_tags
  kms_key_arn             = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_arn
  subnet_ids              = data.terraform_remote_state.common.outputs.private_subnet_ids
  mq_admin_user           = "alf_admin"
  mq_admin_password       = random_password.mq_admin_password.result
  mq_application_user     = "alf_application"
  mq_application_password = random_password.password.result
  identifier              = "alfresco-${random_id.id.hex}"
}
#
