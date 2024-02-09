####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

####################################################
# Locals
####################################################
locals {
  common_name        = "${var.environment_identifier}-${var.alfresco_app_name}"
  vpc_id             = var.vpc_id
  allowed_cidr_block = var.allowed_cidr_block
  tags               = var.tags

  public_cidr_block = [var.public_cidr_block]

  private_cidr_block = [var.private_cidr_block]

  db_cidr_block       = [var.db_cidr_block]
  internal_lb_sg_id   = var.sg_map_ids["internal_lb_sg_id"]
  internal_inst_sg_id = var.sg_map_ids["internal_inst_sg_id"]
  db_sg_id            = var.sg_map_ids["db_sg_id"]
  elasticache_sg_id   = var.sg_map_ids["elasticache_sg_id"]
  external_lb_sg_id   = var.sg_map_ids["external_lb_sg_id"]
  external_inst_sg_id = var.sg_map_ids["external_inst_sg_id"]
}

#######################################
# SECURITY GROUPS
#######################################
#-------------------------------------------------------------
### internal instance sg
#-------------------------------------------------------------
resource "aws_security_group_rule" "internal_lb_ingress_http" {
  security_group_id        = local.internal_inst_sg_id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = local.external_lb_sg_id
  description              = "${local.common_name}-lb-ingress-http"
}

resource "aws_security_group_rule" "internal_lb_ingress_https" {
  security_group_id        = local.internal_inst_sg_id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = local.external_lb_sg_id
  description              = "${local.common_name}-lb-ingress-https"
}

resource "aws_security_group_rule" "internal_lb_ingress_sharepoint" {
  security_group_id        = local.internal_inst_sg_id
  type                     = "ingress"
  from_port                = 7070
  to_port                  = 7070
  protocol                 = "tcp"
  source_security_group_id = local.external_lb_sg_id
  description              = "${local.common_name}-lb-ingress-sharepoint"
}

resource "aws_security_group_rule" "internal_inst_sg_ingress_self" {
  security_group_id = local.internal_inst_sg_id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

resource "aws_security_group_rule" "internal_inst_sg_egress_self" {
  security_group_id = local.internal_inst_sg_id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

resource "aws_security_group_rule" "internal_inst_sg_egress_postgres" {
  security_group_id        = local.internal_inst_sg_id
  type                     = "egress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  source_security_group_id = local.db_sg_id
  description              = "${local.common_name}-rds-sg"
}

resource "aws_security_group_rule" "internal_inst_sg_egress_elasticache" {
  security_group_id        = local.internal_inst_sg_id
  type                     = "egress"
  from_port                = "11211"
  to_port                  = "11211"
  protocol                 = "tcp"
  source_security_group_id = local.elasticache_sg_id
  description              = "${local.common_name}-elasticache-sg"
}

#-------------------------------------------------------------
### rds sg
#-------------------------------------------------------------
resource "aws_security_group_rule" "rds_sg_egress_postgres" {
  security_group_id        = local.db_sg_id
  type                     = "ingress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  source_security_group_id = local.internal_inst_sg_id
  description              = "${local.common_name}-rds-sg"
}

resource "aws_security_group_rule" "rds_sg_egress_postgres" {
  security_group_id        = local.db_sg_id
  type                     = "ingress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  cidr_blocks = (var.environment_identifier == "delius-prod" || var.environment_identifier == "delius-pre-prod") ? var.bastion_cidr.prod : var.bastion_cidr.dev
  description              = "${local.common_name}-rds-bastion-access"
}

#-------------------------------------------------------------
### elasticache sg
#-------------------------------------------------------------
resource "aws_security_group_rule" "elasticache_memchached" {
  security_group_id        = local.elasticache_sg_id
  type                     = "ingress"
  from_port                = "11211"
  to_port                  = "11211"
  protocol                 = "tcp"
  source_security_group_id = local.internal_inst_sg_id
  description              = "${local.common_name}-elasticache-sg"
}

