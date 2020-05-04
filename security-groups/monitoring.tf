resource "aws_security_group" "monitoring_sg" {
  name        = "${local.common_name}-monitoring-elk"
  description = "security group for ${local.common_name}-monitoring"
  vpc_id      = "${local.vpc_id}"

  tags = "${merge(local.tags, map("Name", "${local.common_name}-monitoring-elk"))}"
}

resource "aws_security_group" "monitoring_elb_sg" {
  name        = "${local.common_name}-monitoring-elk-elb"
  description = "security group for ${local.common_name}-monitoring-elk-elb"
  vpc_id      = "${local.vpc_id}"
  tags        = "${merge(local.tags, map("Name", "${local.common_name}-monitoring-elk-elb"))}"
}

resource "aws_security_group" "monitoring_client_sg" {
  name        = "${local.common_name}-monitoring-elk-client"
  description = "security group for ${local.common_name}-elasticsearch"
  vpc_id      = "${local.vpc_id}"

  tags = "${merge(local.tags, map("Name", "${local.common_name}-monitoring-elk-client"))}"
}

resource "aws_security_group" "elasticsearch_sg" {
  name        = "${local.common_name}-monitoring-elasticsearch"
  description = "security group for ${local.common_name}-elasticsearch"
  vpc_id      = "${local.vpc_id}"

  tags = "${merge(local.tags, map("Name", "${local.common_name}-monitoring-elasticsearch"))}"
}

resource "aws_security_group" "mon_efs" {
  name        = "${local.common_name}-monitoring-efs"
  description = "security group for ${local.common_name}-efs"
  vpc_id      = "${local.vpc_id}"

  tags = "${merge(local.tags, map("Name", "${local.common_name}-monitoring-efs"))}"
}

resource "aws_security_group" "mon_jenkins" {
  name        = "${local.common_name}-monitoring-jenkins"
  description = "security group for ${local.common_name}-jenkins"
  vpc_id      = "${local.vpc_id}"

  tags = "${merge(local.tags, map("Name", "${local.common_name}-monitoring-jenkins"))}"
}

# outputs
output "sg_monitoring" {
  value = "${aws_security_group.monitoring_sg.id}"
}

output "sg_monitoring_elb" {
  value = "${aws_security_group.monitoring_elb_sg.id}"
}

output "sg_monitoring_client" {
  value = "${aws_security_group.monitoring_client_sg.id}"
}

output "sg_elasticsearch" {
  value = "${aws_security_group.elasticsearch_sg.id}"
}

output "sg_mon_efs" {
  value = "${aws_security_group.mon_efs.id}"
}

output "sg_mon_jenkins" {
  value = "${aws_security_group.mon_jenkins.id}"
}
