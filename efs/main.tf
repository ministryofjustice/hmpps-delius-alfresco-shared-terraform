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

#-------------------------------------------------------------
### Getting the security groups details
#-------------------------------------------------------------
data "terraform_remote_state" "security-groups" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/security-groups/terraform.tfstate"
    region = var.region
  }
}

####################################################
# Locals
####################################################

locals {
  account_id                   = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id                       = data.terraform_remote_state.common.outputs.vpc_id
  internal_domain              = data.terraform_remote_state.common.outputs.internal_domain
  private_zone_id              = data.terraform_remote_state.common.outputs.private_zone_id
  public_zone_id               = data.terraform_remote_state.common.outputs.public_zone_id
  external_domain              = data.terraform_remote_state.common.outputs.external_domain
  environment_identifier       = data.terraform_remote_state.common.outputs.environment_identifier
  common_name                  = data.terraform_remote_state.common.outputs.common_name
  short_environment_identifier = data.terraform_remote_state.common.outputs.short_environment_identifier
  region                       = var.region
  alfresco_app_name            = data.terraform_remote_state.common.outputs.alfresco_app_name
  environment                  = data.terraform_remote_state.common.outputs.environment
  tags                         = data.terraform_remote_state.common.outputs.common_tags
  s3bucket_kms_arn             = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_arn
  private_subnet_ids           = [data.terraform_remote_state.common.outputs.private_subnet_ids]

  security_groups = [
    data.terraform_remote_state.security-groups.outputs.security_groups_sg_efs_sg_id,
  ]
}

####################################################
# EFS content
####################################################
module "efs_backups" {
  source                          = "../modules/efs"
  environment_identifier          = local.environment_identifier
  tags                            = local.tags
  encrypted                       = true
  kms_key_id                      = local.s3bucket_kms_arn
  performance_mode                = "generalPurpose"
  provisioned_throughput_in_mibps = var.alf_backups_config["provisioned_throughput_in_mibps"]
  throughput_mode                 = var.alf_backups_config["throughput_mode"]
  share_name                      = "${local.alfresco_app_name}-efs"
  zone_id                         = local.private_zone_id
  domain                          = local.internal_domain
  subnets                         = flatten(local.private_subnet_ids)
  security_groups                 = local.security_groups
}

