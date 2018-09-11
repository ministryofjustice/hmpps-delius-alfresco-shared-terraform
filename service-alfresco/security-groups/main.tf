####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

####################################################
# Locals
####################################################
locals {
  common_name        = "${var.environment_identifier}-${var.alfresco_app_name}"
  vpc_id             = "${var.vpc_id}"
  allowed_cidr_block = "${var.allowed_cidr_block}"
  tags               = "${var.tags}"

  public_cidr_block = ["${var.public_cidr_block}"]

  private_cidr_block = ["${var.private_cidr_block}"]

  db_cidr_block = ["${var.db_cidr_block}"]
}

#######################################
# SECURITY GROUPS
#######################################

#-------------------------------------------------------------
### internal lb sg
#-------------------------------------------------------------
resource "aws_security_group" "internal_lb_sg" {
  name        = "${local.common_name}-lb-internal-sg"
  description = "security group for ${local.common_name}-lb-internal-sg"
  vpc_id      = "${local.vpc_id}"
  tags        = "${merge(local.tags, map("Name", "${local.common_name}-lb-internal-sg"))}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "internal_lb_sg_egress_alb_backend_port" {
  security_group_id = "${aws_security_group.internal_lb_sg.id}"
  type              = "egress"
  from_port         = "${var.alb_backend_port}"
  to_port           = "${var.alb_backend_port}"
  protocol          = "tcp"
  cidr_blocks       = ["${local.private_cidr_block}"]
  description       = "${local.common_name}"
}

resource "aws_security_group_rule" "internal_lb_sg_ingress_alb_http_port" {
  security_group_id = "${aws_security_group.internal_lb_sg.id}"
  type              = "ingress"
  from_port         = "${var.alb_http_port}"
  to_port           = "${var.alb_http_port}"
  protocol          = "tcp"
  description       = "${local.common_name}-lb-internal-sg"
  cidr_blocks       = ["${local.allowed_cidr_block}"]
}

resource "aws_security_group_rule" "internal_lb_sg_ingress_alb_https_port" {
  security_group_id = "${aws_security_group.internal_lb_sg.id}"
  type              = "ingress"
  from_port         = "${var.alb_https_port}"
  to_port           = "${var.alb_https_port}"
  protocol          = "tcp"
  cidr_blocks       = ["${local.allowed_cidr_block}"]
  description       = "${local.common_name}-https"
}

#-------------------------------------------------------------
### internal instance sg
#-------------------------------------------------------------
resource "aws_security_group" "internal_instance" {
  name        = "${local.common_name}-instance-internal-sg"
  description = "security group for ${local.common_name}-instance-internal-sg"
  vpc_id      = "${local.vpc_id}"
  tags        = "${merge(local.tags, map("Name", "${local.common_name}-instance-internal-sg"))}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "internal_inst_sg_ingress_self" {
  security_group_id = "${aws_security_group.internal_instance.id}"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

resource "aws_security_group_rule" "internal_inst_sg_egress_self" {
  security_group_id = "${aws_security_group.internal_instance.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

resource "aws_security_group_rule" "internal_inst_sg_ingress_alb_backend_port" {
  security_group_id        = "${aws_security_group.internal_instance.id}"
  type                     = "ingress"
  from_port                = "${var.alb_backend_port}"
  to_port                  = "${var.alb_backend_port}"
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.internal_lb_sg.id}"
  description              = "${local.common_name}-instance-internal-sg"
}

resource "aws_security_group_rule" "internal_inst_sg_ingress_alb_http_port" {
  security_group_id        = "${aws_security_group.internal_instance.id}"
  type                     = "ingress"
  from_port                = "${var.alb_http_port}"
  to_port                  = "${var.alb_http_port}"
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.internal_lb_sg.id}"
  description              = "${local.common_name}-instance-internal-sg"
}

resource "aws_security_group_rule" "internal_inst_sg_egress_postgres" {
  security_group_id = "${aws_security_group.internal_instance.id}"
  type              = "egress"
  from_port         = "5432"
  to_port           = "5432"
  protocol          = "tcp"

  cidr_blocks = ["${local.db_cidr_block}"]

  description = "${local.common_name}-rds-sg"
}

#-------------------------------------------------------------
### rds sg
#-------------------------------------------------------------
resource "aws_security_group" "rds_sg" {
  name        = "${local.common_name}-sg"
  description = "security group for ${local.common_name}-rds-sg"
  vpc_id      = "${local.vpc_id}"
  tags        = "${merge(local.tags, map("Name", "${local.common_name}-rds-sg"))}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "rds_sg_ingress_postgres" {
  security_group_id        = "${aws_security_group.rds_sg.id}"
  type                     = "ingress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  description              = "${local.common_name}-rds-sg"
  source_security_group_id = "${aws_security_group.internal_instance.id}"
}
