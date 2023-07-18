module "ecs_service" {
  source = "../modules/alfresco/ecs-service"
  ecs_config = {
    name                  = local.application_name
    ecs_cluster_name      = data.terraform_remote_state.ecs_cluster.outputs.info["ecs_cluster_name"]
    region                = local.region
    account_id            = local.account_id
    log_group_arn         = module.create_loggroup.loggroup_arn
    desired_count         = var.alf_stop_services == "yes" ? 0 : local.alfresco_content_props["desired_count"]
    deployment_controller = "ECS"
    namespace_id          = local.ecs_cluster_namespace_id
    fluentbit_s3_arn      = format("%s/%s", local.config_bucket_arn, local.fluentbit_s3_path)
    config_bucket_arn     = local.config_bucket_arn
    grace_period          = "300"
  }
  health_check_grace_period_seconds  = "300"
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  security_groups = [
    aws_security_group.app.id,
    data.terraform_remote_state.common.outputs.common_sg_outbound_id,
    data.terraform_remote_state.share.outputs.info["access_security_group"],
    data.terraform_remote_state.transform.outputs.info["access_security_group"],
    data.terraform_remote_state.solr.outputs.info["access_security_group"]
  ]
  subnet_ids = local.subnet_ids
  tags       = local.tags
  secrets = {
    config = aws_ssm_parameter.config.arn
  }
  task_policy_json = data.aws_iam_policy_document.task_policy.json
  container_definitions = templatefile(
    "${path.module}/templates/task_definition.json.tftpl",
    {
      image_url         = format("%s:%s", local.alfresco_content_props["image_url"], var.alfresco_content_image_version)
      container_name    = local.application_name
      region            = local.region
      loggroup          = module.create_loggroup.loggroup_name
      memory            = tonumber(local.alfresco_content_props["memory"])
      cpu               = tonumber(local.alfresco_content_props["cpu"])
      app_port          = tonumber(local.alfresco_content_props["app_port"])
      ssm_java_options  = aws_ssm_parameter.config.arn
      cache_volume_name = local.cache_volume_name
      cache_location    = local.cache_location
      fluentbit_s3_arn  = format("%s/%s", local.config_bucket_arn, local.fluentbit_s3_path)
      delivery_stream   = local.firehose_stream_name
    }
  )
  ebs_volumes = [
    {
      autoprovision = true
      driver        = "rexray/ebs"
      name          = local.cache_volume_name
      scope         = "shared"
      size          = 100
      type          = "gp2"
      kms_key_id    = local.storage_kms_arn
    }
  ]
  load_balancer_targets = [
    {
      target_group_arn = aws_lb_target_group.app.arn
      container_name   = local.container_name
      container_port   = local.app_port
    }
  ]
}
