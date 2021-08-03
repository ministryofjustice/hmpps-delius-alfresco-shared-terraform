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

# app
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
  source_security_group_id = aws_security_group.access.id
  security_group_id        = local.lb_security_group
  type                     = "ingress"
  from_port                = local.target_group_port
  to_port                  = local.target_group_port
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "access_out" {
  source_security_group_id = local.lb_security_group
  security_group_id        = aws_security_group.access.id
  type                     = "egress"
  from_port                = local.target_group_port
  to_port                  = local.target_group_port
  protocol                 = "tcp"
}

# vpn
resource "aws_security_group_rule" "vpn_access_alb" {
  security_group_id = local.lb_security_group
  type              = "ingress"
  from_port         = local.target_group_port
  to_port           = local.target_group_port
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
