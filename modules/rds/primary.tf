############################################
# CREATE DB INSTANCE
############################################

module "db_instance" {
  source = "../db_instance"

  create            = "${var.create_db_instance}"
  identifier        = "${local.common_name}"
  engine            = "${var.engine}"
  engine_version    = "${var.master_engine_version}"
  instance_class    = "${var.rds_instance_class}"
  allocated_storage = "${var.rds_allocated_storage}"
  storage_type      = "${var.storage_type}"
  storage_encrypted = "${var.storage_encrypted}"
  kms_key_id        = "${module.kms_key.kms_arn}"
  license_model     = "${var.license_model}"

  name                                = "${local.db_name}"
  username                            = "${local.db_user_name}"
  password                            = "${local.db_password}"
  port                                = "${var.port}"
  iam_database_authentication_enabled = "${var.iam_database_authentication_enabled}"

  replicate_source_db = "${var.replicate_source_db}"

  snapshot_identifier = "${var.snapshot_identifier}"

  vpc_security_group_ids = [
    "${var.security_group_ids}",
  ]

  db_subnet_group_name = "${module.db_subnet_group.db_subnet_group_id}"
  parameter_group_name = "${module.parameter_group.db_parameter_group_id}"
  option_group_name    = "${module.db_option_group.db_option_group_id}"

  multi_az            = "${var.multi_az}"
  iops                = "${var.iops}"
  publicly_accessible = "${var.publicly_accessible}"

  allow_major_version_upgrade     = "${var.allow_major_version_upgrade}"
  auto_minor_version_upgrade      = "${var.auto_minor_version_upgrade}"
  apply_immediately               = "${var.apply_immediately}"
  maintenance_window              = "${var.maintenance_window}"
  skip_final_snapshot             = "${var.skip_final_snapshot}"
  copy_tags_to_snapshot           = "${var.copy_tags_to_snapshot}"
  final_snapshot_identifier       = "${local.common_name}-final-snapshot"
  enabled_cloudwatch_logs_exports = ["${var.enabled_cloudwatch_logs_exports}"]
  backup_retention_period         = "${var.rds_backup_retention_period}"
  backup_window                   = "${var.backup_window}"

  monitoring_interval  = "${var.rds_monitoring_interval}"
  monitoring_role_arn  = "${module.rds_monitoring_role.iamrole_arn}"
  monitoring_role_name = "${module.rds_monitoring_role.iamrole_name}"

  timezone           = "${var.timezone}"
  character_set_name = "${var.character_set_name}"

  tags = "${local.tags}"
}

###############################################
# Create route53 entry for rds
###############################################

resource "aws_route53_record" "rds_dns_entry" {
  name    = "${local.dns_name}.${var.internal_domain}"
  type    = "CNAME"
  zone_id = "${var.private_zone_id}"
  ttl     = 300
  records = ["${module.db_instance.db_instance_address}"]
}
