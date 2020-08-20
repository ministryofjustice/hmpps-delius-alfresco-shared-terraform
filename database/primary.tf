############################################
# CREATE DB INSTANCE
############################################

module "db_instance" {
  source                          = "../modules/db_instance"
  allocated_storage               = var.alf_rds_props["allocated_storage"]
  allow_major_version_upgrade     = false
  apply_immediately               = false
  auto_minor_version_upgrade      = false
  backup_retention_period         = var.alf_data_import == "enabled" ? 0 : var.alf_rds_props["backup_retention_period"]
  backup_window                   = var.alf_rds_props["backup_window"]
  copy_tags_to_snapshot           = true
  create                          = true
  db_subnet_group_name            = module.db_subnet_group.db_subnet_group_id
  enabled_cloudwatch_logs_exports = flatten(local.enabled_cloudwatch_logs_exports)
  engine                          = local.engine
  engine_version                  = local.master_engine_version
  final_snapshot_identifier       = "${local.common_name}-pri-final-snapshot"
  identifier                      = "${local.common_name}-pri"
  instance_class                  = var.alf_rds_props["instance_class"]
  iops                            = var.alf_rds_props["iops"]
  kms_key_id                      = module.kms_key.kms_arn
  maintenance_window              = var.alf_rds_props["maintenance_window"]
  monitoring_interval             = 30
  monitoring_role_arn             = module.rds_monitoring_role.iamrole_arn
  monitoring_role_name            = module.rds_monitoring_role.iamrole_name
  multi_az                        = var.alf_data_import == "enabled" ? false : true
  name                            = local.db_name
  option_group_name               = module.db_option_group.db_option_group_id
  parameter_group_name            = module.parameter_group.db_parameter_group_id
  password                        = local.db_password
  port                            = local.port
  publicly_accessible             = false
  skip_final_snapshot             = false
  snapshot_identifier             = var.alf_snapshot_identifier
  storage_encrypted               = true
  storage_type                    = var.alf_rds_props["storage_type"]
  tags                            = local.tags
  username                        = local.db_user_name
  vpc_security_group_ids          = flatten(local.security_group_ids)
}

###############################################
# Create route53 entry for rds
###############################################

resource "aws_route53_record" "rds_dns_entry" {
  name    = "${local.dns_name}.${local.internal_domain}"
  type    = "CNAME"
  zone_id = local.private_zone_id
  ttl     = 300
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [module.db_instance.db_instance_address]
}

