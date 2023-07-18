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
  alfresco_ro_content_props = merge(var.alfresco_ro_content_props, var.alfresco_ro_content_configs)
  region                    = var.region
  account_id                = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id                    = data.terraform_remote_state.common.outputs.vpc_id
  prefix                    = data.terraform_remote_state.common.outputs.short_environment_identifier
  application_name          = "alfresco-read"
  application_short_name    = "alf-read"
  common_name               = format("%s-%s", local.prefix, local.application_name)
  tags                      = data.terraform_remote_state.common.outputs.common_tags
  logs_kms_arn              = data.terraform_remote_state.common.outputs.kms_arn
  fluent_config_file        = "fluent.conf"
  fluentbit_s3_path         = format("ecs-services/%s/%s", local.application_name, local.fluent_config_file)
  firehose_stream_name      = data.terraform_remote_state.firehose.outputs.info["stream_name"]
  config_bucket_name        = data.terraform_remote_state.common.outputs.common_s3-config-bucket
  config_bucket_arn         = data.aws_s3_bucket.config_bucket.arn
  storage_bucket_name       = data.terraform_remote_state.s3bucket.outputs.s3bucket
  storage_bucket_arn        = data.aws_s3_bucket.storage_bucket.arn
  storage_kms_arn           = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_arn
  database_security_group   = data.terraform_remote_state.rds.outputs.info["security_group_id"]
  ecs_cluster_namespace_id  = data.terraform_remote_state.ecs_cluster.outputs.info["ecs_cluster_namespace_id"]
  solr_security_group       = data.terraform_remote_state.solr.outputs.info["app_security_group"]
  share_security_group      = data.terraform_remote_state.share.outputs.info["app_security_group"]
  transform_security_group  = data.terraform_remote_state.transform.outputs.info["app_security_group"]
  internal_lb_security_grp  = data.terraform_remote_state.load_balancer.outputs.info["security_group_id"]
  external_lb_security_grp  = data.terraform_remote_state.external_load_balancer.outputs.info["security_group_id"]
  cache_volume_name         = format("%s-cache-volume", local.common_name)
  cache_location            = "/srv/alf_data"
  subnet_ids                = data.terraform_remote_state.common.outputs.private_subnet_ids
  lb_arn                    = data.terraform_remote_state.load_balancer.outputs.info["arn"]

  internal_private_dns_host = data.terraform_remote_state.load_balancer.outputs.info["dns_hostname"]
  external_private_dns_host = data.terraform_remote_state.external_load_balancer.outputs.info["dns_hostname"]
  lb_security_group         = data.terraform_remote_state.load_balancer.outputs.info["security_group_id"]

  solr_port         = 8983
  app_port          = tonumber(local.alfresco_ro_content_props["app_port"])
  target_group_port = tonumber(local.alfresco_ro_content_props["target_group_port"])
  http_protocol     = "HTTP"
  container_name    = local.application_name
  url_path_patterns = [
    "/*"
  ]
  access_group_id = data.terraform_remote_state.security_groups.outputs.alf_access_groups["content"]
}

