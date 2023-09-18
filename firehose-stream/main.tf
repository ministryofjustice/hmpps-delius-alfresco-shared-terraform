terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {
  }
}

####################################################
# Locals
####################################################

locals {
  alfresco_firehose_props = merge(var.alf_firehose_configs, var.alf_firehose_overrides)
  account_id              = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id                  = data.terraform_remote_state.common.outputs.vpc_id
  common_name             = format("%s-alf-firehose", data.terraform_remote_state.common.outputs.short_environment_identifier)
  region                  = var.region
  environment             = data.terraform_remote_state.common.outputs.environment
  tags                    = data.terraform_remote_state.common.outputs.common_tags
  logs_kms_arn            = data.terraform_remote_state.common.outputs.kms_arn
  # Commented out pending testing
  # es_security-grp         = data.terraform_remote_state.elk.outputs.elk_service["es_sg_id"]
  # es_cluster_arn          = data.terraform_remote_state.elk.outputs.elk_service["arn"]
  private_subnet_ids = data.terraform_remote_state.common.outputs.private_subnet_ids
}
