resource "aws_security_group" "es" {
  name        = "${local.common_name}-sg"
  description = "${local.common_name}-sg"
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    {
      "Name" = "${local.common_name}-sg"
    },
  )
}

resource "aws_security_group_rule" "ingress_self" {
  security_group_id = aws_security_group.es.id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

resource "aws_security_group_rule" "egress_self" {
  security_group_id = aws_security_group.es.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

resource "aws_security_group_rule" "ingress_https" {
  security_group_id = aws_security_group.es.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [local.vpc_cidr_block]
  description       = "${local.common_name}-https"
}
