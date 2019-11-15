############################################
# CREATE DB INSTANCE REPLICA
############################################
locals {
  replica_common_name = "${local.common_name}-rpl"
}

resource "aws_db_instance" "inst" {
  allocated_storage                   = "${var.alf_rds_props["allocated_storage"]}"
  allow_major_version_upgrade         = false
  allow_major_version_upgrade         = false
  count                               = "${var.alf_data_import == "enabled" ? 0 : 1}"
  enabled_cloudwatch_logs_exports     = ["${local.enabled_cloudwatch_logs_exports}"]
  engine                              = "${local.engine}"
  engine_version                      = "${local.master_engine_version}"
  final_snapshot_identifier           = "${local.replica_common_name}"
  iam_database_authentication_enabled = false
  identifier                          = "${local.replica_common_name}"
  instance_class                      = "${var.alf_rds_props["instance_class"]}"
  iops                                = "${var.alf_rds_props["iops"]}"
  kms_key_id                          = "${module.kms_key.kms_arn}"
  maintenance_window                  = "${var.alf_rds_props["maintenance_window"]}"
  multi_az                            = "${var.alf_data_import == "enabled" ? false : true}"
  option_group_name                   = "${module.db_option_group.db_option_group_id}"
  parameter_group_name                = "${module.parameter_group.db_parameter_group_id}"
  password                            = ""
  port                                = "${local.port}"
  publicly_accessible                 = false
  replicate_source_db                 = "${module.db_instance.db_instance_id}"
  skip_final_snapshot                 = "${var.alf_data_import == "enabled" ? true : false}"
  storage_encrypted                   = true
  storage_type                        = "${var.alf_rds_props["storage_type"]}"
  tags                                = "${merge(local.tags, map("Name", format("%s", local.replica_common_name)))}"
  username                            = ""
  vpc_security_group_ids = [
    "${local.security_group_ids}",
  ]
}

###############################################
# Create route53 entry for rds
###############################################

resource "aws_route53_record" "rds_dns_replica" {
  name    = "${local.dns_name}_rpl.${local.internal_domain}"
  type    = "CNAME"
  zone_id = "${local.private_zone_id}"
  ttl     = 300
  records = ["${aws_db_instance.inst.address}"]
  count   = "${var.alf_data_import == "enabled" ? 0 : 1}"
}
