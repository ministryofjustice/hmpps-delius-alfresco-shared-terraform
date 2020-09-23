############################################
# CREATE DB INSTANCE
############################################
resource "aws_security_group" "sg_solr_db" {
  name        = "${local.common_name}-db"
  description = "GDPR SOLR db"
  vpc_id      = "${local.vpc_id}"
  tags        = "${merge(local.tags, map("Name", "${local.common_name}"))}"
}


module "db_instance" {
  source                          = "../modules/db_instance"
  allocated_storage               = "${var.alf_rds_props["allocated_storage"]}"
  allow_major_version_upgrade     = false
  apply_immediately               = false
  auto_minor_version_upgrade      = false
  backup_retention_period         = "${var.alf_data_import == "enabled" ? 0 : var.alf_rds_props["backup_retention_period"]}"
  backup_window                   = "${var.alf_rds_props["backup_window"]}"
  copy_tags_to_snapshot           = true
  create                          = true
  db_subnet_group_name            = "${module.db_subnet_group.db_subnet_group_id}"
  enabled_cloudwatch_logs_exports = ["${local.enabled_cloudwatch_logs_exports}"]
  engine                          = "${local.engine}"
  engine_version                  = "${local.master_engine_version}"
  final_snapshot_identifier       = "${local.common_name}-pri-final-snapshot"
  identifier                      = "${local.common_name}-pri"
  instance_class                  = "${var.environment_name == "delius-prod" ? "db.m5.2xlarge" : var.alf_rds_props["instance_class"]}"
  iops                            = "${var.alf_rds_props["iops"]}"
  kms_key_id                      = "${local.db_kms_key_arn}"
  maintenance_window              = "${var.alf_rds_props["maintenance_window"]}"
  monitoring_interval             = 30
  monitoring_role_arn             = "${module.rds_monitoring_role.iamrole_arn}"
  monitoring_role_name            = "${module.rds_monitoring_role.iamrole_name}"
  multi_az                        = "${var.alf_data_import == "enabled" ? false : true}"
  name                            = "${local.db_name}"
  option_group_name               = "${module.db_option_group.db_option_group_id}"
  parameter_group_name            = "${module.parameter_group.db_parameter_group_id}"
  password                        = "${local.db_password}"
  port                            = "${local.port}"
  publicly_accessible             = false
  skip_final_snapshot             = false
  snapshot_identifier             = "" #"${var.gdpr_solr_snapshot_identifier}"
  storage_encrypted               = true
  storage_type                    = "${var.alf_rds_props["storage_type"]}"
  tags                            = "${local.tags}"
  username                        = "${local.db_user_name}"
  vpc_security_group_ids = [
    "${aws_security_group.sg_solr_db.id}",
  ]
}
