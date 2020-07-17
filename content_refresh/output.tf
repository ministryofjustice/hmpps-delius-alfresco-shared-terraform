output "redis" {
  value = "${aws_elasticache_cluster.redis.cache_nodes}"
}

