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

output "loggroup_name" {
  value = {
    elasticsearch = "${module.create_loggroup.loggroup_name}"
  }
}

# ECS Service
output "ecs_service_id" {
  value = "${aws_ecs_service.elk_service.id}"
}

output "ecs_service_name" {
  value = "${aws_ecs_service.elk_service.name}"
}

output "migration_server_internal_url" {
  value = "${aws_route53_record.internal_migration_dns.fqdn}"
}

# logstash
output "internal_logstash_host" {
  value = "${aws_route53_record.internal_logstash_dns.fqdn}"
}
