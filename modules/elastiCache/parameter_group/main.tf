resource "aws_elasticache_parameter_group" "default" {
  name   = "${var.name}-parameter-group"
  family = var.family

  parameter {
    name  = "max_item_size"
    value = var.max_item_size
  }
}

