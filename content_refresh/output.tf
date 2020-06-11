output "redis" {
  value = "${aws_elasticache_cluster.redis.cache_nodes}"
}

output "loggroup_name" {
  value = "${module.create_loggroup.loggroup_name}"
}
