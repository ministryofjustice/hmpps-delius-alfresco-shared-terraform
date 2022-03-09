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
  alfresco_share_props         = merge(var.alfresco_share_props, var.alfresco_share_configs, var.alf_config_map)
  region                       = var.region
  account_id                   = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id                       = data.terraform_remote_state.common.outputs.vpc_id
  prefix                       = data.terraform_remote_state.common.outputs.short_environment_identifier
  application_name             = "alfresco-share-ecs"
  application_short_name       = "alf-share"
  common_name                  = format("%s-%s", local.prefix, local.application_name)
  tags                         = data.terraform_remote_state.common.outputs.common_tags
  logs_kms_arn                 = data.terraform_remote_state.common.outputs.kms_arn
  config_bucket_name           = data.terraform_remote_state.common.outputs.common_s3-config-bucket
  config_bucket_arn            = data.aws_s3_bucket.config_bucket.arn
  storage_kms_arn              = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_arn
  ecs_cluster_namespace_id     = data.terraform_remote_state.ecs_cluster.outputs.info["ecs_cluster_namespace_id"]
  ecs_cluster_namespace_domain = data.terraform_remote_state.ecs_cluster.outputs.info["ecs_cluster_namespace_domain"]
  service_discovery_name       = format("%s.%s", local.application_name, local.ecs_cluster_namespace_domain)
  internal_private_dns_host    = data.terraform_remote_state.load_balancer.outputs.info["dns_hostname"]
  lb_security_group            = data.terraform_remote_state.load_balancer.outputs.info["security_group_id"]
  lb_arn                       = data.terraform_remote_state.load_balancer.outputs.info["arn"]
  subnet_ids                   = data.terraform_remote_state.common.outputs.private_subnet_ids
  app_port                     = tonumber(local.alfresco_share_props["app_port"])
  alfresco_port                = tonumber(local.alfresco_share_props["alfresco_port"])
  target_group_port            = tonumber(local.alfresco_share_props["target_group_port"])
  http_protocol                = "HTTP"
  container_name               = local.application_name
  url_path_patterns = [
    "/*"
  ]
  web_extension_volume    = format("%s-web-extensions", local.common_name)
  content_access_group_id = data.terraform_remote_state.security_groups.outputs.alf_access_groups["content"]
  access_group_id         = data.terraform_remote_state.security_groups.outputs.alf_access_groups["share"]
}
