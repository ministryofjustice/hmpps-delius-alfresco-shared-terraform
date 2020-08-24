resource "aws_security_group_rule" "internal_inst_sg_egress_mq" {
  security_group_id        = local.mon_jenkins_sg
  type                     = "egress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  source_security_group_id = local.sg_rds_id
  description              = "${local.common_name}-esadmin-out"
}

#-------------------------------------------------------------
### rds sg
#-------------------------------------------------------------
resource "aws_security_group_rule" "rds_sg_ingress_postgres" {
  security_group_id        = local.sg_rds_id
  type                     = "ingress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  source_security_group_id = local.mon_jenkins_sg
  description              = "${local.common_name}-esadmin-in"
}

# efs
resource "aws_security_group_rule" "efs_nfs_out" {
  security_group_id        = local.mon_jenkins_sg
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = local.alf_efs_sg
  description              = "${local.common_name}-efs_nfs_out"
}

resource "aws_security_group_rule" "efs_nfs_in" {
  security_group_id        = local.alf_efs_sg
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = local.mon_jenkins_sg
  description              = "${local.common_name}-efs_nfs_in"
}

