resource "aws_security_group" "sg_tracker_alb" {
  name        = "${local.common_name}-alb"
  description = "Allow tracker access"
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    {
      "Name" = local.common_name
    },
  )
}

locals {
  instance_sg = data.terraform_remote_state.security-groups.outputs.security_groups_sg_internal_instance_id
}

# rules
resource "aws_security_group_rule" "tracker_from_alb" {
  security_group_id        = local.instance_sg
  type                     = "ingress"
  from_port                = local.http_port
  to_port                  = local.http_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_tracker_alb.id
  description              = "alb to tracker"
}

resource "aws_security_group_rule" "alb_to_tracker" {
  security_group_id        = aws_security_group.sg_tracker_alb.id
  type                     = "egress"
  from_port                = local.http_port
  to_port                  = local.http_port
  protocol                 = "tcp"
  source_security_group_id = local.instance_sg
  description              = "alb to tracker"
}

# external
resource "aws_security_group_rule" "external_lb_ingress_http" {
  security_group_id = aws_security_group.sg_tracker_alb.id
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  type              = "ingress"
  description       = "${local.common_name}-http"
  cidr_blocks       = flatten(local.allowed_cidr_block)
}

resource "aws_security_group_rule" "external_lb_ingress_https" {
  security_group_id = aws_security_group.sg_tracker_alb.id
  from_port         = local.https_port
  to_port           = local.https_port
  protocol          = "tcp"
  type              = "ingress"
  description       = "${local.common_name}-https"
  cidr_blocks       = flatten(local.allowed_cidr_block)
}

# alfresco to alb
resource "aws_security_group_rule" "alf_lb_ingress_http" {
  security_group_id        = aws_security_group.sg_tracker_alb.id
  from_port                = local.http_port
  to_port                  = local.http_port
  protocol                 = "tcp"
  type                     = "ingress"
  description              = "${local.common_name}-alf-http"
  source_security_group_id = local.instance_sg
}

resource "aws_security_group_rule" "alf_lb_ingress_https" {
  security_group_id        = aws_security_group.sg_tracker_alb.id
  from_port                = local.https_port
  to_port                  = local.https_port
  protocol                 = "tcp"
  type                     = "ingress"
  description              = "${local.common_name}-alf-https"
  source_security_group_id = local.instance_sg
}

resource "aws_security_group_rule" "alf_lb_egress_http" {
  security_group_id        = local.instance_sg
  from_port                = local.http_port
  to_port                  = local.http_port
  protocol                 = "tcp"
  type                     = "egress"
  description              = "${local.common_name}-alf-http"
  source_security_group_id = aws_security_group.sg_tracker_alb.id
}

resource "aws_security_group_rule" "alf_lb_egress_https" {
  security_group_id        = local.instance_sg
  from_port                = local.https_port
  to_port                  = local.https_port
  protocol                 = "tcp"
  type                     = "egress"
  description              = "${local.common_name}-alf-https"
  source_security_group_id = aws_security_group.sg_tracker_alb.id
}

