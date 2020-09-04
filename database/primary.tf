############################################
# CREATE DB INSTANCE
############################################

module "db_instance" {
  source                          = "../modules/db_instance"
  allocated_storage               = lookup(var.alf_rds_props, "allocated_storage", 30)
  allow_major_version_upgrade     = false
  apply_immediately               = false
  auto_minor_version_upgrade      = false
  backup_retention_period         = var.alf_data_import == "enabled" ? 0 : lookup(var.alf_rds_props, "backup_retention_period", 28)
  backup_window                   = lookup(var.alf_rds_props, "backup_window", "02:00-04:00")
  copy_tags_to_snapshot           = true
  create                          = true
  db_subnet_group_name            = module.db_subnet_group.db_subnet_group_id
  enabled_cloudwatch_logs_exports = flatten(local.enabled_cloudwatch_logs_exports)
  engine                          = local.engine
  engine_version                  = local.master_engine_version
  final_snapshot_identifier       = "${local.common_name}-pri-final-snapshot"
  identifier                      = "${local.common_name}-pri"
  instance_class                  = lookup(var.alf_rds_props, "instance_class", "db.t2.medium")
  iops                            = lookup(var.alf_rds_props, "iops", 10)
  kms_key_id                      = module.kms_key.kms_arn
  maintenance_window              = lookup(var.alf_rds_props, "maintenance_window", "wed:19:30-wed:21:30")
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
  storage_type                    = lookup(var.alf_rds_props, "storage_type", "gp2")
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
  records = [module.db_instance.db_instance_address]
}
