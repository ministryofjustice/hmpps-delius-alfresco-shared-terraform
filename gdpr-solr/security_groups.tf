resource "aws_security_group" "sg_solr_inst" {
  name        = "${local.common_name}-ec2"
  description = "Allow SOLR & Alfresco access"
  vpc_id      = "${local.vpc_id}"
  tags        = "${merge(local.tags, map("Name", "${local.common_name}"))}"
}

locals {
  instance_sg = "${aws_security_group.sg_solr_inst.id}"
  db_sg       = "${data.terraform_remote_state.rds.db_security_group}"
}


# rules
resource "aws_security_group_rule" "solr_to_db" {
  security_group_id        = "${local.db_sg}"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = "${local.instance_sg}"
}

resource "aws_security_group_rule" "db_allow" {
  security_group_id        = "${local.instance_sg}"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = "${local.db_sg}"
}

resource "aws_security_group_rule" "bastion_tunnel_alf" {
  security_group_id = "${local.instance_sg}"
  type              = "ingress"
  from_port         = "8080"
  to_port           = "8080"
  protocol          = "tcp"
  cidr_blocks       = ["${values(data.terraform_remote_state.vpc.bastion_vpc_public_cidr)}"]
  description       = "bastion tunnelling"
}

resource "aws_security_group_rule" "bastion_tunnel_solr" {
  security_group_id = "${local.instance_sg}"
  type              = "ingress"
  from_port         = "8983"
  to_port           = "8983"
  protocol          = "tcp"
  cidr_blocks       = ["${values(data.terraform_remote_state.vpc.bastion_vpc_public_cidr)}"]
  description       = "bastion tunnelling"
}
