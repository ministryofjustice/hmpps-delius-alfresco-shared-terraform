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

resource "aws_security_group_rule" "solr_in" {
  source_security_group_id = aws_security_group.app.id
  security_group_id        = local.solr_security_group
  type                     = "ingress"
  from_port                = local.solr_port
  to_port                  = local.solr_port
  protocol                 = "tcp"
}

# vpn
resource "aws_security_group_rule" "vpn_access_alb" {
  security_group_id = local.lb_security_group
  type              = "ingress"
  from_port         = local.app_port
  to_port           = local.app_port
  protocol          = "tcp"
  cidr_blocks       = local.vpn_source_cidrs
  description       = "vpn tunnelling"
}

resource "aws_security_group_rule" "vpn_access" {
  security_group_id = aws_security_group.app.id
  type              = "ingress"
  from_port         = local.app_port
  to_port           = local.app_port
  protocol          = "tcp"
  cidr_blocks       = local.vpn_source_cidrs
  description       = "vpn tunnelling"
}

# alfresco
locals {
  alfresco_access_groups = {
    solr        = local.solr_security_group
    external_lb = local.external_lb_security_grp
  }
}
resource "aws_security_group_rule" "alfresco_in" {
  for_each                 = local.alfresco_access_groups
  security_group_id        = aws_security_group.app.id
  source_security_group_id = each.value
  type                     = "ingress"
  from_port                = local.app_port
  to_port                  = local.app_port
  protocol                 = "tcp"
  description              = format("%s outbound rule", each.key)
}

resource "aws_security_group_rule" "alfresco_out" {
  for_each                 = local.alfresco_access_groups
  security_group_id        = each.value
  source_security_group_id = aws_security_group.app.id
  type                     = "ingress"
  from_port                = local.app_port
  to_port                  = local.app_port
  protocol                 = "tcp"
  description              = format("%s inbound rule", each.key)
}
