resource "aws_security_group_rule" "vpn_postgres" {
  security_group_id = data.terraform_remote_state.security-groups.outputs.security_groups_sg_rds_id
  type              = "ingress"
  from_port         = local.port
  to_port           = local.port
  protocol          = "tcp"
  cidr_blocks       = data.terraform_remote_state.common.outputs.vpn_info["source_cidrs"]
  description       = "vpn tunnelling"
}
