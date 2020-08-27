#
# ElastiCache Resources
#

locals {
  port     = "11211"
  dns_name = "memcached.${var.domain}"
}

resource "aws_elasticache_cluster" "default" {
  cluster_id             = var.cluster_id
  engine                 = "memcached"
  engine_version         = var.engine_version
  node_type              = var.instance_type
  parameter_group_name   = var.parameter_group_name
  subnet_group_name      = var.subnet_group_name
  security_group_ids     = var.security_group_ids
  maintenance_window     = var.maintenance_window
  notification_topic_arn = var.notification_topic_arn
  port                   = local.port
  az_mode                = var.cluster_size == 1 ? "single-az" : "cross-az"
  num_cache_nodes        = var.cluster_size
  tags                   = var.tags
}

###############################################
# Create route53 entry for nodes
###############################################

resource "aws_route53_record" "dns_entry" {
  name    = local.dns_name
  type    = "CNAME"
  zone_id = var.zone_id
  ttl     = 300

  records = [aws_elasticache_cluster.default.cluster_address]
}

