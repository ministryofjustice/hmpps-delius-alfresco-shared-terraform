resource "aws_elasticache_subnet_group" "default" {
  name        = "${var.name}-subnet-group"
  description = "${var.name} subnet group"
  subnet_ids  = var.subnets
}

