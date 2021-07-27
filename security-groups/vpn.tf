resource "aws_security_group_rule" "vpn_http_alt" {
  security_group_id = local.sg_map_ids["internal_inst_sg_id"]
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = local.vpn_source_cidrs
  description       = "vpn access"
}

resource "aws_security_group_rule" "vpn_ssh" {
  security_group_id = local.sg_map_ids["internal_inst_sg_id"]
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = local.vpn_source_cidrs
  description       = "vpn access"
}
