############################################
# CREATE DB INSTANCE REPLICA
############################################

resource "aws_db_instance" "inst" {
  identifier                          = "${local.replica_common_name}"
  enabled_cloudwatch_logs_exports     = ["${var.enabled_cloudwatch_logs_exports}"]
  engine                              = "${var.engine}"
  engine_version                      = "${var.engine_version}"
  instance_class                      = "${var.rds_instance_class}"
  allocated_storage                   = "${var.rds_allocated_storage}"
  storage_type                        = "${var.storage_type}"
  storage_encrypted                   = "${var.storage_encrypted}"
  kms_key_id                          = "${module.kms_key.kms_arn}"
  username                            = ""
  password                            = ""
  port                                = "${var.port}"
  iam_database_authentication_enabled = "${var.iam_database_authentication_enabled}"
  replicate_source_db                 = "${module.db_instance.db_instance_id}"
  count                               = "${var.data_import == "enabled" ? 0 : 1}"
  skip_final_snapshot                 = "${var.data_import == "enabled" ? true : false}"
  final_snapshot_identifier           = "${local.replica_common_name}-replica"
  parameter_group_name                = "${module.parameter_group.db_parameter_group_id}"
  option_group_name                   = "${module.db_option_group.db_option_group_id}"
  multi_az                            = "${var.multi_az}"
  iops                                = "${var.iops}"
  publicly_accessible                 = "${var.publicly_accessible}"
  maintenance_window                  = "${var.maintenance_window}"
  tags                                = "${merge(local.tags, map("Name", format("%s", local.replica_common_name)))}"
  vpc_security_group_ids = [
    "${var.security_group_ids}",
  ]
}

###############################################
# Create route53 entry for rds
###############################################

resource "aws_route53_record" "rds_dns_replica" {
  name    = "${local.dns_name}-rpl.${var.internal_domain}"
  type    = "CNAME"
  zone_id = "${var.private_zone_id}"
  ttl     = 300
  records = ["${aws_db_instance.inst.address}"]
  count   = "${var.data_import == "enabled" ? 0 : 1}"
}
