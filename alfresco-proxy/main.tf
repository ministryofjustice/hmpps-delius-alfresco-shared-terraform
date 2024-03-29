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
  alfresco_proxy_props         = merge(var.alfresco_proxy_props, var.alfresco_proxy_configs)
  region                       = var.region
  account_id                   = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id                       = data.terraform_remote_state.common.outputs.vpc_id
  prefix                       = data.terraform_remote_state.common.outputs.short_environment_identifier
  application_name             = "alfresco-proxy"
  application_short_name       = "alf-proxy"
  common_name                  = format("%s-%s", local.prefix, local.application_name)
  tags                         = data.terraform_remote_state.common.outputs.common_tags
  logs_kms_arn                 = data.terraform_remote_state.common.outputs.kms_arn
  fluent_config_file           = "fluent.conf"
  fluentbit_s3_path            = format("ecs-services/%s/%s", local.application_name, local.fluent_config_file)
  firehose_stream_name         = data.terraform_remote_state.firehose.outputs.info["stream_name"]
  config_bucket_name           = data.terraform_remote_state.common.outputs.common_s3-config-bucket
  config_bucket_arn            = data.aws_s3_bucket.config_bucket.arn
  storage_kms_arn              = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_arn
  ecs_cluster_namespace_id     = data.terraform_remote_state.ecs_cluster.outputs.info["ecs_cluster_namespace_id"]
  ecs_cluster_namespace_domain = data.terraform_remote_state.ecs_cluster.outputs.info["ecs_cluster_namespace_domain"]
  service_discovery_name       = format("%s.%s", local.application_name, local.ecs_cluster_namespace_domain)
  internal_private_dns_host    = data.terraform_remote_state.load_balancer.outputs.info["dns_hostname"]
  external_private_dns_host    = data.terraform_remote_state.external_load_balancer.outputs.info["dns_hostname"]
  lb_security_group            = data.terraform_remote_state.external_load_balancer.outputs.info["security_group_id"]
  lb_arn                       = data.terraform_remote_state.external_load_balancer.outputs.info["arn"]
  subnet_ids                   = data.terraform_remote_state.common.outputs.private_subnet_ids
  app_port                     = tonumber(local.alfresco_proxy_props["app_port"])
  http_protocol                = "HTTP"
  container_name               = local.application_name
  certificate_arn              = data.aws_acm_certificate.cert.arn
  url_path_patterns = [
    "/alfresco/*",
    "/share/*"
  ]
  nginx_volume = format("%s-nginx_config", local.common_name)
  allowed_cidr_block = [
    distinct(concat(var.user_access_cidr_blocks, var.alfresco_access_cidr_blocks)),
    data.terraform_remote_state.common.outputs.nat_gateway_ips,
  ]
  task_definition_file = var.alf_push_to_cloudwatch == "yes" ? "task_definition-cloudwatch.conf" : "task_definition.conf"
}

