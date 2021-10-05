#Namespace
resource "aws_service_discovery_private_dns_namespace" "ecs_namespace" {
  name        = local.alf_ecs_config["ecs_cluster_namespace_name"]
  description = "Private namespace for Alfresco ECS Cluster"
  vpc         = local.vpc_id
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs" {
  name = local.ecs_cluster_name
  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 1
  }
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = merge(local.tags, { Name = local.ecs_cluster_name })
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = local.ecs_cluster_name
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "ENABLED"
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = tonumber(local.alf_ecs_config["ecs_cluster_target_capacity"])
      maximum_scaling_step_size = tonumber(local.alf_ecs_config["ecs_maximum_scaling_step_size"])
    }
  }
  tags = merge(local.tags, { Name = local.ecs_cluster_name })
}
