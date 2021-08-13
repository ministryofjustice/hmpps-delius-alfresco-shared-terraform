resource "aws_ecs_task_definition" "task_def" {
  family                   = format("%s-task-definition", var.ecs_config["name"])
  container_definitions    = var.container_definitions
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  tags = merge(
    var.tags,
    {
      "Name" = format("%s-task-definition", var.ecs_config["name"])
    }
  )

  dynamic "volume" {
    for_each = var.ebs_volumes
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
  name            = format("%s-service", var.ecs_config["name"])
  cluster         = var.ecs_config["ecs_cluster_name"]
  task_definition = aws_ecs_task_definition.task_def.arn
  desired_count   = tonumber(var.ecs_config["desired_count"])
  network_configuration {
    security_groups = var.security_groups
    subnets         = var.subnet_ids
  }
  capacity_provider_strategy {
    capacity_provider = var.ecs_config["capacity_provider"]
    weight            = 1
  }

  deployment_controller {
    type = var.ecs_config["deployment_controller"]
  }

  # service_registries {
  #   registry_arn = aws_service_discovery_service.kibana.arn
  # }

  # load_balancer {
  #   target_group_arn = module.kibana_target_grp.target_group_arn
  #   container_name   = local.kibana_container_name
  #   container_port   = local.kibana_port
  # }
  dynamic "load_balancer" {
    for_each = var.load_balancer_targets
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }
}
