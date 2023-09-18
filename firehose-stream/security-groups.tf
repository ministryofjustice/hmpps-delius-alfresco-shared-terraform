resource "aws_security_group" "firehose" {
  name        = "${local.common_name}-sg"
  description = "${local.common_name}-sg"
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    {
      "Name" = "${local.common_name}-sg"
    },
  )
}

# Commented out pending testing
# resource "aws_security_group_rule" "egress_es" {
#   security_group_id        = aws_security_group.firehose.id
#   type                     = "egress"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "tcp"
#   source_security_group_id = local.es_security-grp
#   description              = "${local.common_name}-access"
# }

# resource "aws_security_group_rule" "ingress_from_firehose" {
#   security_group_id        = local.es_security-grp 
#   type                     = "ingress"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.firehose.id
#   description              = "${local.common_name}-access"
# }
