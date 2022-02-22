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

resource "aws_security_group" "kibana" {
  name        = "${local.common_name}-${local.kibana_container_name}"
  description = "${local.common_name}-${local.kibana_container_name}"
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    {
      "Name" = "${local.common_name}-${local.kibana_container_name}"
    },
  )
}

resource "aws_security_group" "access_es" {
  name        = "${local.common_name}-es-access"
  description = "${local.common_name}-es-access"
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    {
      "Name" = "${local.common_name}-es-access"
    },
  )
}

resource "aws_security_group" "lb" {
  name        = "${local.common_name}-kb-lb"
  description = "${local.common_name}-kb-lb"
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    {
      "Name" = "${local.common_name}-kb-lb"
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

resource "aws_security_group_rule" "bastion_ingress" {
  security_group_id = aws_security_group.es.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks = [
    local.bastion_cidrs["az1"],
    local.bastion_cidrs["az2"],
    local.bastion_cidrs["az3"]
  ]
  description = "${local.common_name}-https"
}

resource "aws_security_group_rule" "ingress_ext_kibana" {
  security_group_id = aws_security_group.lb.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = flatten(local.allowed_cidr_block)
  description       = "${local.common_name}-https"
}

resource "aws_security_group_rule" "egress_kibana" {
  security_group_id        = aws_security_group.lb.id
  type                     = "egress"
  from_port                = 5601
  to_port                  = 5601
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.kibana.id
  description              = "${local.common_name}-kibana"
}

resource "aws_security_group_rule" "ingress_kibana" {
  security_group_id        = aws_security_group.kibana.id
  type                     = "ingress"
  from_port                = 5601
  to_port                  = 5601
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb.id
  description              = "${local.common_name}-kibana"
}

resource "aws_security_group_rule" "egress_es" {
  security_group_id        = aws_security_group.kibana.id
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.es.id
  description              = "${local.common_name}-es"
}

resource "aws_security_group_rule" "kibana_es" {
  security_group_id        = aws_security_group.es.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.kibana.id
  description              = "${local.common_name}-https"
}

resource "aws_security_group_rule" "idp_auth_out" {
  protocol          = "tcp"
  security_group_id = aws_security_group.lb.id
  from_port         = 443
  to_port           = 443
  type              = "egress"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
}

resource "aws_security_group_rule" "access_egress" {
  security_group_id        = aws_security_group.access_es.id
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.es.id
  description              = "${local.common_name}-es"
}

resource "aws_security_group_rule" "access_ingress" {
  security_group_id        = aws_security_group.es.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.access_es.id
  description              = "${local.common_name}-es"
}
