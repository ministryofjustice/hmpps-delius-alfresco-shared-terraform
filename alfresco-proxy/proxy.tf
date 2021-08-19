module "ecs_service" {
  source = "../modules/alfresco/ecs-service"
  ecs_config = {
    name                  = local.application_name
    ecs_cluster_name      = data.terraform_remote_state.ecs_cluster.outputs.info["ecs_cluster_name"]
    region                = local.region
    account_id            = local.account_id
    log_group_arn         = module.create_loggroup.loggroup_arn
    desired_count         = tonumber(local.alfresco_proxy_props["desired_count"])
    capacity_provider     = data.terraform_remote_state.ecs_cluster.outputs.capacity_provider["name"]
    deployment_controller = "ECS"
    namespace_id          = local.ecs_cluster_namespace_id
  }
  security_groups = [
    aws_security_group.app.id,
    data.terraform_remote_state.common.outputs.common_sg_outbound_id,
    data.terraform_remote_state.share.outputs.info["access_security_group"],
    data.terraform_remote_state.content.outputs.info["access_security_group"]
  ]
  subnet_ids       = local.subnet_ids
  tags             = local.tags
  task_policy_json = data.aws_iam_policy_document.task_policy.json
  container_definitions = templatefile(
    "${path.module}/templates/task_definitions/task_definition.conf",
    {
      image_url      = format("%s:%s", local.alfresco_proxy_props["image_url"], local.alfresco_proxy_props["version"])
      container_name = local.container_name
      region         = local.region
      loggroup       = module.create_loggroup.loggroup_name
      memory         = tonumber(local.alfresco_proxy_props["memory"])
      cpu            = tonumber(local.alfresco_proxy_props["cpu"])
      app_port       = local.app_port
      nginx_host     = base64encode(data.template_file.nginx_host.rendered)
      nginx_volume   = local.nginx_volume
    }
  )
  ebs_volumes = [
    {
      autoprovision = true
      driver        = "rexray/ebs"
      name          = local.nginx_volume
      scope         = "shared"
      size          = 1
      type          = "gp2"
      kms_key_id    = local.storage_kms_arn
      iops          = 100
    }
  ]
  # load_balancer_targets = [
  #   {
  #     target_group_arn = aws_lb_target_group.app.arn
  #     container_name   = local.container_name
  #     container_port   = local.app_port
  #   }
  # ]
}
