resource "aws_security_group" "app" {
  name        = local.common_name
  description = "security group for ${local.common_name}-traffic"
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    {
      "Name" = local.common_name
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

# database
resource "aws_security_group_rule" "postgres_out" {
  security_group_id        = aws_security_group.app.id
  source_security_group_id = local.database_security_group
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "postgres_in" {
  source_security_group_id = aws_security_group.app.id
  security_group_id        = local.database_security_group
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
}

# solr 
resource "aws_security_group_rule" "solr_out" {
  security_group_id        = aws_security_group.app.id
  source_security_group_id = local.solr_security_group
  type                     = "egress"
  from_port                = local.solr_port
  to_port                  = local.solr_port
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "solr_out_lb" {
  security_group_id        = aws_security_group.app.id
  source_security_group_id = local.internal_lb_security_grp
  type                     = "egress"
  from_port                = local.solr_port
  to_port                  = local.solr_port
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "solr_in" {
  source_security_group_id = aws_security_group.app.id
  security_group_id        = local.solr_security_group
  type                     = "ingress"
  from_port                = local.solr_port
  to_port                  = local.solr_port
  protocol                 = "tcp"
}
