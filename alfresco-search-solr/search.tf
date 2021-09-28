module "ecs_service" {
  source = "../modules/alfresco/ecs-service"
  ecs_config = {
    name                  = local.application_name
    ecs_cluster_name      = data.terraform_remote_state.ecs_cluster.outputs.info["ecs_cluster_name"]
    region                = local.region
    account_id            = local.account_id
    log_group_arn         = module.create_loggroup.loggroup_arn
    desired_count         = var.alf_stop_services == "yes" ? 0 : length(local.subnet_ids)
    capacity_provider     = data.terraform_remote_state.ecs_cluster.outputs.capacity_provider["name"]
    deployment_controller = "ECS"
    namespace_id          = local.ecs_cluster_namespace_id
    fluentbit_s3_arn      = format("%s/%s", local.config_bucket_arn, local.fluentbit_s3_path)
    config_bucket_arn     = local.config_bucket_arn
  }
  security_groups = [
    aws_security_group.app.id,
    data.terraform_remote_state.common.outputs.common_sg_outbound_id
  ]
  subnet_ids       = local.subnet_ids
  tags             = local.tags
  task_policy_json = data.aws_iam_policy_document.task_policy.json
  container_definitions = templatefile(
    "${path.module}/templates/task_definitions/task_definition.conf",
    {
      image_url          = format("%s:%s", local.alfresco_search_solr_props["image_url"], local.alfresco_search_solr_props["version"])
      container_name     = local.container_name
      region             = local.region
      loggroup           = module.create_loggroup.loggroup_name
      memory             = tonumber(local.alfresco_search_solr_props["memory"])
      cpu                = tonumber(local.alfresco_search_solr_props["cpu"])
      app_port           = local.solr_port
      solr_alfresco_host = local.internal_private_dns_host
      solr_alfresco_port = 9000
      solr_solr_host     = local.internal_private_dns_host
      cache_volume_name  = local.cache_volume_name
      data_volume_name   = local.data_volume_name
      logs_volume_name   = local.logs_volume_name
      fluentbit_s3_arn   = format("%s/%s", local.config_bucket_arn, local.fluentbit_s3_path)
      delivery_stream    = local.firehose_stream_name
    }
  )
  load_balancer_targets = [
    {
      target_group_arn = aws_lb_target_group.app.arn
      container_name   = local.container_name
      container_port   = local.solr_port
    }
  ]
  ebs_volumes = [
    {
      autoprovision = true
      driver        = "rexray/ebs"
      name          = local.cache_volume_name
      scope         = "shared"
      size          = 100
      type          = "gp2"
      kms_key_id    = local.storage_kms_arn
      iops          = 300
    },
    {
      autoprovision = false
      driver        = "rexray/ebs"
      name          = local.data_volume_name
      scope         = "shared"
      size          = local.alfresco_search_solr_props["ebs_size"]
      type          = local.alfresco_search_solr_props["ebs_type"]
      kms_key_id    = local.storage_kms_arn
      iops          = tonumber(local.ebs_type == "gp2" ? 0 : local.ebs_iops)
    },
    {
      autoprovision = true
      driver        = "rexray/ebs"
      name          = local.logs_volume_name
      scope         = "shared"
      size          = 100
      type          = "gp2"
      kms_key_id    = local.storage_kms_arn
      iops          = 300
    }
  ]
}
