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
          iops       = volume.value.iops
          encrypted  = true
          kmsKeyID   = volume.value.kms_key_id
        }
      }
    }
  }
}

resource "aws_ecs_service" "ecs_service" {
  name                               = var.ecs_config["name"]
  cluster                            = var.ecs_config["ecs_cluster_name"]
  task_definition                    = aws_ecs_task_definition.task_def.arn
  desired_count                      = tonumber(var.ecs_config["desired_count"])
  health_check_grace_period_seconds  = tonumber(var.health_check_grace_period_seconds)
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  network_configuration {
    security_groups = var.security_groups
    subnets         = var.subnet_ids
  }

  deployment_controller {
    type = var.ecs_config["deployment_controller"]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.svc_record.arn
    container_name = var.ecs_config["name"]
  }
  dynamic "load_balancer" {
    for_each = var.load_balancer_targets
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

  lifecycle {
    # ignore changes to capacity_provider_strategy as config is inherited from cluster defaults
    ignore_changes = [capacity_provider_strategy]
  }
}

resource "aws_service_discovery_service" "svc_record" {
  name = var.ecs_config["name"]

  dns_config {
    namespace_id = var.ecs_config["namespace_id"]

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
