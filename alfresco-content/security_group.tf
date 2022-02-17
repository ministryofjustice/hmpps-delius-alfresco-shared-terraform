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

resource "aws_security_group" "access" {
  name        = format("%s-access", local.common_name)
  description = "security group for ${local.common_name}-access-traffic"
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    {
      "Name" = format("%s-access", local.common_name)
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

resource "aws_security_group_rule" "solr_in" {
  source_security_group_id = aws_security_group.app.id
  security_group_id        = local.solr_security_group
  type                     = "ingress"
  from_port                = local.solr_port
  to_port                  = local.solr_port
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "solr_access_in" {
  source_security_group_id = local.solr_security_group
  security_group_id        = local.lb_security_group
  type                     = "ingress"
  from_port                = local.app_port
  to_port                  = local.app_port
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "solr_access_out" {
  source_security_group_id = local.lb_security_group
  security_group_id        = local.solr_security_group
  type                     = "egress"
  from_port                = local.app_port
  to_port                  = local.app_port
  protocol                 = "tcp"
}

# vpn
resource "aws_security_group_rule" "vpn_access" {
  security_group_id = aws_security_group.app.id
  type              = "ingress"
  from_port         = local.app_port
  to_port           = local.app_port
  protocol          = "tcp"
  cidr_blocks       = local.vpn_source_cidrs
  description       = "vpn tunnelling"
}

resource "aws_security_group_rule" "vpn_access_alb" {
  count             = 0 # share service creates similar rule
  security_group_id = local.lb_security_group
  type              = "ingress"
  from_port         = local.app_port
  to_port           = local.app_port
  protocol          = "tcp"
  cidr_blocks       = local.vpn_source_cidrs
  description       = "vpn tunnelling"
}

# alfresco
resource "aws_security_group_rule" "lb_out" {
  security_group_id        = local.lb_security_group
  source_security_group_id = aws_security_group.app.id
  type                     = "egress"
  from_port                = local.app_port
  to_port                  = local.app_port
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "lb_in" {
  source_security_group_id = local.lb_security_group
  security_group_id        = aws_security_group.app.id
  type                     = "ingress"
  from_port                = local.app_port
  to_port                  = local.app_port
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "access_in" {
  source_security_group_id = local.access_group_id
  security_group_id        = local.lb_security_group
  type                     = "ingress"
  from_port                = local.app_port
  to_port                  = local.app_port
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "access_out" {
  source_security_group_id = local.lb_security_group
  security_group_id        = local.access_group_id
  type                     = "egress"
  from_port                = local.app_port
  to_port                  = local.app_port
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "hazelcast_in" {
  cidr_blocks       = [for s in data.aws_subnet.ecs_subnets : s.cidr_block]
  security_group_id = aws_security_group.app.id
  type              = "ingress"
  from_port         = 5701
  to_port           = 5701
  protocol          = "tcp"
  description       = "Hazelcast cluster"
}

resource "aws_security_group_rule" "hazelcast_out" {
  cidr_blocks       = [for s in data.aws_subnet.ecs_subnets : s.cidr_block]
  security_group_id = aws_security_group.app.id
  type              = "egress"
  from_port         = 5701
  to_port           = 5701
  protocol          = "tcp"
  description       = "Hazelcast cluster"
}
