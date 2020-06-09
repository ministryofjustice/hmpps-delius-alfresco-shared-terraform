resource "aws_security_group" "redis" {
  name   = "${local.common_name}-esadmin-redis"
  vpc_id = "${local.vpc_id}"
  tags   = "${merge(local.tags, map("Name", "${local.common_name}-esadmin-redis"))}"
}

resource "aws_security_group_rule" "redis_ingress_self" {
  security_group_id = "${aws_security_group.redis.id}"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

resource "aws_security_group_rule" "redis_egress_self" {
  security_group_id = "${aws_security_group.redis.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${local.common_name}-esadmin-redis"
  subnet_ids = ["${local.private_subnet_ids}"]
}

resource "aws_elasticache_parameter_group" "redis" {
  name   = "esadmin-redis"
  family = "redis5.0"
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "esadmin-redis"
  engine               = "redis"
  node_type            = "cache.m4.large"
  num_cache_nodes      = 1
  parameter_group_name = "${aws_elasticache_parameter_group.redis.id}"
  engine_version       = "5.0.6"
  port                 = 6379
  subnet_group_name    = "${aws_elasticache_subnet_group.redis.name}"
  security_group_ids   = ["${aws_security_group.redis.id}"]
}
