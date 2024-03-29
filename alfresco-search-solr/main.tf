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
  alfresco_search_solr_props   = merge(var.alfresco_search_solr_props, var.alfresco_search_solr_configs, var.alfresco_search_solr_configs_overrides)
  region                       = var.region
  account_id                   = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id                       = data.terraform_remote_state.common.outputs.vpc_id
  prefix                       = data.terraform_remote_state.common.outputs.short_environment_identifier
  application_name             = "alfresco-search-solr"
  application_short_name       = "alf-solr"
  common_name                  = format("%s-%s", local.prefix, local.application_name)
  tags                         = data.terraform_remote_state.common.outputs.common_tags
  logs_kms_arn                 = data.terraform_remote_state.common.outputs.kms_arn
  fluent_config_file           = "fluent.conf"
  fluentbit_s3_path            = format("ecs-services/%s/%s", local.application_name, local.fluent_config_file)
  firehose_stream_name         = data.terraform_remote_state.firehose.outputs.info["stream_name"]
  config_bucket_name           = data.terraform_remote_state.common.outputs.common_s3-config-bucket
  config_bucket_arn            = data.aws_s3_bucket.config_bucket.arn
  storage_bucket_name          = data.terraform_remote_state.s3bucket.outputs.s3bucket
  storage_bucket_arn           = data.aws_s3_bucket.storage_bucket.arn
  storage_kms_arn              = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_arn
  database_security_group      = data.terraform_remote_state.rds.outputs.info["security_group_id"]
  cache_volume_name            = format("%s-cache-vol", local.common_name)
  data_volume_name             = format("%s-data-volume", local.application_name)
  logs_volume_name             = format("%s-logs-vol", local.common_name)
  ecs_cluster_namespace_id     = data.terraform_remote_state.ecs_cluster.outputs.info["ecs_cluster_namespace_id"]
  ecs_cluster_namespace_domain = data.terraform_remote_state.ecs_cluster.outputs.info["ecs_cluster_namespace_domain"]
  service_discovery_name       = format("%s.%s", local.application_name, local.ecs_cluster_namespace_domain)
  internal_private_dns_host    = data.terraform_remote_state.load_balancer.outputs.info["dns_hostname"]
  lb_security_group            = data.terraform_remote_state.load_balancer.outputs.info["security_group_id"]
  lb_arn                       = data.terraform_remote_state.load_balancer.outputs.info["arn"]
  subnet_ids                   = data.terraform_remote_state.common.outputs.private_subnet_ids
  ebs_iops                     = tonumber(local.alfresco_search_solr_props["ebs_iops"])
  ebs_type                     = local.alfresco_search_solr_props["ebs_type"]
  solr_port                    = tonumber(local.alfresco_search_solr_props["app_port"])
  http_protocol                = "HTTP"
  lambda_name                  = "${var.environment_identifier}-${local.application_short_name}-cleanup-scheduler"
  lambda_file                  = "volume_cleanup"
  sns_topic_arn                = data.terraform_remote_state.monitoring.outputs.sns_topic_arn
  cleanup_scheduler_log_group  = "/aws/lambda/${local.lambda_name}"
  container_name               = local.application_name
  task_definition_file         = var.alf_push_to_cloudwatch == "yes" ? "task_definition-cloudwatch.conf" : "task_definition.conf"
  url_path_patterns = [
    "/solr/*"
  ]

  ebs_volumes = [
    {
      autoprovision = false
      driver        = "rexray/ebs"
      name          = local.cache_volume_name
      scope         = "task"
      size          = 100
      type          = "gp3"
      kms_key_id    = local.storage_kms_arn
      iops          = null
    },
    {
      autoprovision = false
      driver        = "rexray/ebs"
      name          = local.data_volume_name
      scope         = "shared"
      size          = local.alfresco_search_solr_props["ebs_size"]
      type          = "gp3"
      kms_key_id    = local.storage_kms_arn
      iops          = try(local.ebs_iops, null)
    },
    {
      autoprovision = true
      driver        = "rexray/ebs"
      name          = local.logs_volume_name
      scope         = "shared"
      size          = 100
      type          = "gp3"
      iops          = null
      kms_key_id    = local.storage_kms_arn
    }
  ]
}
