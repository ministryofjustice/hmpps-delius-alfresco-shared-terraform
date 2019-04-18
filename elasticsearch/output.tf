# ECS
output "ecs_cluster_arn" {
  value = "${module.ecs_cluster.ecs_cluster_arn}"
}

output "ecs_cluster_id" {
  value = "${module.ecs_cluster.ecs_cluster_id}"
}

output "ecs_cluster_name" {
  value = "${module.ecs_cluster.ecs_cluster_name}"
}

# LOG GROUPS
output "loggroup_arn" {
  value = "${module.create_loggroup.loggroup_arn}"
}

output "loggroup_name" {
  value = "${module.create_loggroup.loggroup_name}"
}

# Task definition
output "task_definition_arn" {
  value = "${aws_ecs_task_definition.environment.arn}"
}

output "task_definition_family" {
  value = "${aws_ecs_task_definition.environment.family}"
}

output "task_definition_revision" {
  value = "${aws_ecs_task_definition.environment.revision}"
}

# ECS Service
output "ecs_service_id" {
  value = "${module.app_service.ecs_service_id}"
}

output "ecs_service_name" {
  value = "${module.app_service.ecs_service_name}"
}
