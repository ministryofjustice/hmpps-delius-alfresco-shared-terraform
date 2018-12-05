# # LB
output "ecs_nginx_lb_id" {
  value = "${module.ecs-nginx.lb_id}"
}

output "ecs_nginx_lb_arn" {
  value = "${module.ecs-nginx.lb_arn}"
}

output "ecs_nginx_lb_dns_name" {
  value = "${module.ecs-nginx.lb_dns_name}"
}

output "ecs_nginx_lb_dns_alias" {
  value = "${module.ecs-nginx.lb_dns_alias}"
}

output "ecs_nginx_lb_zone_id" {
  value = "${module.ecs-nginx.lb_zone_id}"
}

# ECS CLUSTER
output "ecs_nginx_ecs_cluster_arn" {
  value = "${module.ecs-nginx.ecs_cluster_arn}"
}

output "ecs_nginx_ecs_cluster_id" {
  value = "${module.ecs-nginx.ecs_cluster_id}"
}

output "ecs_nginx_ecs_cluster_name" {
  value = "${module.ecs-nginx.ecs_cluster_name}"
}

# LOG GROUPS
output "ecs_nginx_loggroup_arn" {
  value = "${module.ecs-nginx.loggroup_arn}"
}

output "ecs_nginx_loggroup_name" {
  value = "${module.ecs-nginx.loggroup_name}"
}

# TASK DEFINITION
output "ecs_nginx_task_definition_arn" {
  value = "${module.ecs-nginx.task_definition_arn}"
}

output "ecs_nginx_task_definition_family" {
  value = "${module.ecs-nginx.task_definition_family}"
}

output "ecs_nginx_task_definition_revision" {
  value = "${module.ecs-nginx.task_definition_revision}"
}

# ECS SERVICE
output "ecs_nginx_service_id" {
  value = "${module.ecs-nginx.ecs_service_id}"
}

output "ecs_nginx_service_name" {
  value = "${module.ecs-nginx.ecs_service_name}"
}

output "ecs_nginx_service_cluster" {
  value = "${module.ecs-nginx.ecs_service_cluster}"
}

# Launch config
output "ecs_nginx_launch_id" {
  value = "${module.ecs-nginx.launch_id}"
}

output "ecs_nginx_launch_name" {
  value = "${module.ecs-nginx.launch_name}"
}

# ASG
output "autoscale_id" {
  value = "${module.ecs-nginx.autoscale_id}"
}

output "ecs_nginx_autoscale_arn" {
  value = "${module.ecs-nginx.autoscale_arn}"
}

output "ecs_nginx_autoscale_name" {
  value = "${module.ecs-nginx.autoscale_name}"
}
