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

# LB
output "es_elb_id" {
  description = "The name of the ELB"
  value       = "${module.create_app_elb.environment_elb_id}"
}

output "es_elb_name" {
  description = "The name of the ELB"
  value       = "${module.create_app_elb.environment_elb_name}"
}

output "es_elb_dns_name" {
  description = "The DNS name of the ELB"
  value       = "${module.create_app_elb.environment_elb_dns_name}"
}

output "es_elb_source_security_group_id" {
  description = "The ID of the security group that you can use as part of your inbound rules for your load balancer's back-end application instances"
  value       = "${module.create_app_elb.environment_elb_source_security_group_id}"
}

output "es_elb_zone_id" {
  description = "The canonical hosted zone ID of the ELB (to be used in a Route 53 Alias record)"
  value       = "${module.create_app_elb.environment_elb_zone_id}"
}

output "es_elb_dns_cname" {
  value = "${aws_route53_record.dns_entry.fqdn}"
}
