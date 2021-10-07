resource "aws_ecs_task_definition" "task_def" {
  family = format("%s-task-definition", local.application_name)
  container_definitions = templatefile(
    "${path.module}/templates/task_definitions/${local.task_definition_file}",
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
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  tags = merge(
    local.tags,
    {
      "Name" = format("%s-task-definition", local.application_name)
    }
  )

  dynamic "volume" {
    for_each = local.ebs_volumes
    content {
      name = volume.value.name
      docker_volume_configuration {
        scope         = volume.value.scope
        autoprovision = volume.value.autoprovision
        driver        = volume.value.driver
        driver_opts = {
          volumetype = volume.value.type
          size       = volume.value.size
          encrypted  = true
          kmsKeyID   = volume.value.kms_key_id
        }
      }
    }
  }
}

resource "aws_ecs_service" "ecs_service" {
  for_each        = toset(local.subnet_ids)
  name            = format("%s-%s", local.application_name, each.key)
  cluster         = data.terraform_remote_state.ecs_cluster.outputs.info["ecs_cluster_name"]
  task_definition = aws_ecs_task_definition.task_def.arn
  desired_count   = var.alf_stop_services == "yes" ? 0 : 1
  network_configuration {
    security_groups = [
      aws_security_group.app.id,
      data.terraform_remote_state.common.outputs.common_sg_outbound_id
    ]
    subnets = tolist([each.key])
  }
  capacity_provider_strategy {
    capacity_provider = data.terraform_remote_state.ecs_cluster.outputs.capacity_provider["name"]
    weight            = 1
  }

  deployment_controller {
    type = "ECS"
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.svc_record.arn
    container_name = local.application_name
  }
  dynamic "load_balancer" {
    for_each = local.load_balancer_targets
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "host"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [eu-west-2a, eu-west-2b, eu-west-2c]"
  }
}

resource "aws_service_discovery_service" "svc_record" {
  name = local.application_name

  dns_config {
    namespace_id = local.ecs_cluster_namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
