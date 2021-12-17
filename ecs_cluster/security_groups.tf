resource "aws_security_group" "ecs_host_sg" {
  name        = "${local.common_name}-host"
  description = "Alfresco ECS Cluster Hosts Security Group"
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    { Name = "${local.common_name}-host" }
  )
}

locals {
  ecs_security_groups = {
    host = aws_security_group.ecs_host_sg.id
    efs  = aws_security_group.ecs_efs_sg.id
  }
}

resource "aws_security_group_rule" "all_out" {
  for_each          = local.ecs_security_groups
  security_group_id = each.value
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  description       = format("%s all outbound", each.key)
}

resource "aws_security_group" "ecs_efs_sg" {
  name        = "${local.common_name}-efs"
  description = "Alfresco ECS Cluster efs Security Group"
  vpc_id      = local.vpc_id
  tags = merge(
    local.tags,
    { Name = "${local.common_name}-efs" }
  )
}

resource "aws_security_group_rule" "vpn_ssh" {
  security_group_id = local.ecs_security_groups["host"]
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = data.terraform_remote_state.common.outputs.vpn_info["source_cidrs"]
  description       = "vpn tunnelling"
}

resource "aws_security_group_rule" "bastion_ssh" {
  security_group_id = local.ecs_security_groups["host"]
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = data.terraform_remote_state.common.outputs.bastion_cidr_ranges
  description       = "bastion access"
}
