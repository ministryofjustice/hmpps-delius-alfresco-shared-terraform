module "ecs_service" {
  source = "../modules/alfresco/ecs-service"
  ecs_config = {
    name                  = local.common_name
    ecs_cluster_name      = data.terraform_remote_state.ecs_cluster.outputs.info["ecs_cluster_name"]
    region                = local.region
    account_id            = local.account_id
    log_group_arn         = module.create_loggroup.loggroup_arn
    storage_bucket_name   = local.storage_bucket_name
    storage_bucket_arn    = local.storage_bucket_arn
    storage_kms_arn       = local.storage_kms_arn
    desired_count         = local.alfresco_content_props["desired_count"]
    capacity_provider     = data.terraform_remote_state.ecs_cluster.outputs.capacity_provider["name"]
    deployment_controller = "ECS"
  }
  security_groups = [
    aws_security_group.app.id,
    data.terraform_remote_state.common.outputs.common_sg_outbound_id
  ]
  subnets_ids = data.terraform_remote_state.common.outputs.private_subnet_ids
  tags        = local.tags
  secrets = {
    config = aws_ssm_parameter.config.arn
  }
  task_policy_json = data.aws_iam_policy_document.task_policy.json
  container_definitions = templatefile(
    "${path.module}/templates/task_definitions/task_definition.conf",
    {
      image_url         = format("%s:%s", local.alfresco_content_props["image_url"], local.alfresco_content_props["version"])
      container_name    = local.application_name
      region            = local.region
      loggroup          = module.create_loggroup.loggroup_name
      memory            = tonumber(local.alfresco_content_props["memory"])
      cpu               = tonumber(local.alfresco_content_props["cpu"])
      app_port          = tonumber(local.alfresco_content_props["app_port"])
      ssm_java_options  = aws_ssm_parameter.config.arn
      cache_volume_name = local.cache_volume_name
      cache_location    = local.cache_location
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
}
