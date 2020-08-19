output "cluster_address" {
  value       = aws_elasticache_cluster.default.cluster_address
  description = "cluster_address"
}

output "cache_nodes" {
  value       = aws_elasticache_cluster.default.cache_nodes
  description = "cache_nodes"
}

output "port" {
  value       = local.port
  description = "Port"
}

output "config_host" {
  value       = aws_elasticache_cluster.default.configuration_endpoint
  description = "Config host"
}

output "dns_host_cname" {
  value       = aws_route53_record.dns_entry.name
  description = "Config host cname"
}

