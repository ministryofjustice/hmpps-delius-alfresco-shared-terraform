terraform {
  # The configuration for this backend will be filled in by Terragrunt
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {
  }
}

####################################################
# Locals
####################################################

locals {
  alfresco_content_props    = merge(var.alfresco_content_props, var.alfresco_content_configs)
  region                    = var.region
  account_id                = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id                    = data.terraform_remote_state.common.outputs.vpc_id
  prefix                    = data.terraform_remote_state.common.outputs.short_environment_identifier
  application_name          = "alfresco-content"
  common_name               = format("%s-%s", local.prefix, local.application_name)
  tags                      = data.terraform_remote_state.common.outputs.common_tags
  logs_kms_arn              = data.terraform_remote_state.common.outputs.kms_arn
  storage_bucket_name       = data.terraform_remote_state.s3bucket.outputs.s3bucket
  storage_bucket_arn        = data.aws_s3_bucket.storage_bucket.arn
  storage_kms_arn           = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_arn
  database_security_group   = data.terraform_remote_state.rds.outputs.info["security_group_id"]
  solr_security_group       = data.terraform_remote_state.solr.outputs.info["app_security_group"]
  internal_lb_security_grp  = data.terraform_remote_state.load_balancer.outputs.info["security_group_id"]
  external_lb_security_grp  = data.terraform_remote_state.external_load_balancer.outputs.info["security_group_id"]
  cache_volume_name         = format("%s-cache-volume", local.common_name)
  cache_location            = "/srv/alf_data"
  subnet_ids                = data.terraform_remote_state.common.outputs.private_subnet_ids
  internal_private_dns_host = data.terraform_remote_state.load_balancer.outputs.info["dns_hostname"]
  external_private_dns_host = data.terraform_remote_state.external_load_balancer.outputs.info["dns_hostname"]
  solr_port                 = 8983
  app_port                  = tonumber(local.alfresco_content_props["app_port"])
}
