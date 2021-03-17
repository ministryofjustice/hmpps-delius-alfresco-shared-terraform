resource "aws_security_group" "environment" {
  name        = "inter-db-in"
  vpc_id      = local.vpc_id
  description = "db incoming"
  tags = merge(
    local.tags,
    {
      "Name" = local.common_name
      "Type" = "WEB"
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

# All local open
resource "aws_security_group_rule" "local_ingress" {
  security_group_id = aws_security_group.environment.id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

resource "aws_security_group_rule" "local_egress" {
  security_group_id = aws_security_group.environment.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

#-------------------------------------------------------------
### common sg rules
#-------------------------------------------------------------

resource "aws_security_group_rule" "ssh_in" {
  security_group_id = aws_security_group.environment.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  type              = "ingress"
  description       = "${local.common_name}-ssh-in"

  cidr_blocks = [
    "217.33.148.210/32",
    "81.134.202.29/32",
    "109.153.234.4/32",
  ]
}

resource "aws_security_group_rule" "http" {
  security_group_id = aws_security_group.environment.id
  type              = "egress"
  from_port         = "8080"
  to_port           = "8080"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "${local.common_name}-http"
}

resource "aws_security_group_rule" "https" {
  security_group_id = aws_security_group.environment.id
  type              = "egress"
  from_port         = "8443"
  to_port           = "8443"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "${local.common_name}-https"
}

