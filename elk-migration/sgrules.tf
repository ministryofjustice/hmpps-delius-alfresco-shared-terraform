resource "aws_security_group_rule" "es_self_in" {
  from_port         = 0
  protocol          = -1
  security_group_id = "${local.mon_jenkins_sg}"
  to_port           = 0
  type              = "ingress"
  self              = true
}

resource "aws_security_group_rule" "es_self_out" {
  from_port         = 0
  protocol          = -1
  security_group_id = "${local.mon_jenkins_sg}"
  to_port           = 0
  type              = "egress"
  self              = true
}

# idp
resource "aws_security_group_rule" "idp_auth_out" {
  protocol          = "tcp"
  security_group_id = "${data.terraform_remote_state.security-groups.security_groups_sg_external_lb_id}"
  from_port         = 0
  to_port           = 65535
  type              = "egress"
  cidr_blocks = [
    "0.0.0.0/0",
  ]

}
