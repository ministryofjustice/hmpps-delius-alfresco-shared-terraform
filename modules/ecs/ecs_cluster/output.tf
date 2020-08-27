output "ecs_cluster_arn" {
  value = aws_ecs_cluster.environment.arn
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.environment.id
}

output "ecs_cluster_name" {
  value = "${var.cluster_name}-ecs-cluster"
}

