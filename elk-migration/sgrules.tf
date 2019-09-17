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
