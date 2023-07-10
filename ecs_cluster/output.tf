output "info" {
  value = {
    ecs_cluster_arn              = aws_ecs_cluster.ecs.arn
    ecs_cluster_name             = aws_ecs_cluster.ecs.name
    ecs_cluster_namespace_id     = aws_service_discovery_private_dns_namespace.ecs_namespace.id
    ecs_cluster_namespace_domain = local.alf_ecs_config["ecs_cluster_namespace_name"]
    efs_security_group_id        = local.ecs_security_groups["efs"]
  }
}

output "capacity_provider" {
  value = aws_ecs_capacity_provider.ecs_capacity_provider
}

output "ecs_auto_sacling_group" {
  value = aws_autoscaling_group.ecs_asg
}

output "az1_capacity_provider" {
  value = aws_ecs_capacity_provider.ecs_az1_capacity_provider
}

output "ecs_az1_auto_sacling_group" {
  value = aws_autoscaling_group.ecs_az1_asg
}