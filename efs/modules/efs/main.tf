locals {
  environment_identifier = "${var.environment_identifier}-${var.share_name}"
  tags                   = "${var.tags}"
  dns_host               = "${var.share_name}.${var.domain}"
}

###############################################
# Create EFS
###############################################
resource "aws_efs_file_system" "efs" {
  creation_token   = "${local.environment_identifier}"
  kms_key_id       = "${var.kms_key_id}"
  encrypted        = "${var.encrypted}"
  performance_mode = "${var.performance_mode}"
  throughput_mode  = "${var.throughput_mode}"

  tags = "${merge(
    var.tags,
    map("Name", "${local.environment_identifier}")
  )}"
}

###############################################
# Create route53 entry for efs
###############################################

resource "aws_route53_record" "dns_entry" {
  name    = "${local.dns_host}"
  type    = "CNAME"
  zone_id = "${var.zone_id}"
  ttl     = 300
  records = ["${aws_efs_file_system.efs.dns_name}"]
}

###############################################
# Create efs mount target
###############################################
resource "aws_efs_mount_target" "efs" {
  count           = "${length(var.subnets)}"
  file_system_id  = "${aws_efs_file_system.efs.id}"
  subnet_id       = "${element(compact(var.subnets), count.index)}"
  security_groups = ["${var.security_groups}"]
}
