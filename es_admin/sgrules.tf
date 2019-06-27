resource "aws_security_group_rule" "internal_inst_sg_egress_mq" {
  security_group_id        = "${local.mon_jenkins_sg}"
  type                     = "egress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_rds_id}"
  description              = "${local.common_name}-esadmin-out"
}

#-------------------------------------------------------------
### rds sg
#-------------------------------------------------------------
resource "aws_security_group_rule" "rds_sg_ingress_postgres" {
  security_group_id        = "${local.sg_rds_id}"
  type                     = "ingress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  source_security_group_id = "${local.mon_jenkins_sg}"
  description              = "${local.common_name}-esadmin-in"
}
