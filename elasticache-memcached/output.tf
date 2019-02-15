output "subnet-group-name" {
  value = "${module.subnet_group.name}"
}

output "parameter-group-id" {
  value = "${module.parameter_group.id}"
}

#cluster 
output "cluster_address" {
  value = "${module.memcached.cluster_address}"
}

output "cache_nodes" {
  value = "${module.memcached.cache_nodes}"
}

output "config_host" {
  value = "${module.memcached.config_host}"
}

output "config_host_cname" {
  value       = "${module.memcached.dns_host_cname}"
  description = "Config host cname"
}
