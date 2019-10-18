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
    kibana        = "${module.kibana_loggroup.loggroup_name}"
    logstash      = "${module.logstash_loggroup.loggroup_name}"
    redis         = "${module.redis_loggroup.loggroup_name}"
  }
}

output "loggroup_prefix" {
  value = "${local.common_name}"
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

output "public_es_host_name" {
  value = "${local.es_host_url}"
}

# logstash
output "internal_logstash_host" {
  value = "${local.logstash_host_fqdn}"
}

# kibana
output "kibana_host" {
  value = "${local.kibana_host_url}"
}

# efs
output "efs_map" {
  value = {
    dns = "${aws_efs_file_system.efs.dns_name}"
    id  = "${aws_efs_file_system.efs.id}"
    arn = "${aws_efs_file_system.efs.arn}"
  }
}
