terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {
  }
}

####################################################
# Locals
####################################################

locals {
  alf_ecs_config     = merge(var.alf_ecs_config, var.alf_config_overrides)
  account_id         = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id             = data.terraform_remote_state.common.outputs.vpc_id
  common_name        = format("%s-alf-app", data.terraform_remote_state.common.outputs.short_environment_identifier)
  region             = var.region
  environment        = data.terraform_remote_state.common.outputs.environment
  tags               = data.terraform_remote_state.common.outputs.common_tags
  private_subnet_ids = [data.terraform_remote_state.common.outputs.private_subnet_ids]
  logs_kms_arn       = data.terraform_remote_state.common.outputs.kms_arn
  ssh_deployer_key   = data.terraform_remote_state.common.outputs.common_ssh_deployer_key
  ecs_cluster_name   = format("%s-services", local.common_name)
  kms_key_arn        = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_arn
}
