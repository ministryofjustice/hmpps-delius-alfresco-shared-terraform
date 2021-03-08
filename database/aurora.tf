data "aws_db_snapshot" "snapshot" {
  db_snapshot_identifier = "alfresco-aurora-snapshot" #var.alf_snapshot_identifier
  most_recent            = true
}

module "db" {
  source                          = "terraform-aws-modules/rds-aurora/aws"
  version                         = "2.26.0"
  name                            = "alf-database-svc"
  database_name                   = local.db_name
  username                        = local.db_user_name
  password                        = local.db_password
  kms_key_id                      = module.kms_key.kms_arn
  engine                          = "aurora-postgresql"
  engine_version                  = "9.6.18"
  snapshot_identifier             = data.aws_db_snapshot.snapshot.db_snapshot_arn
  vpc_id                          = local.vpc_id
  subnets                         = flatten(local.db_subnet_ids)
  replica_count                   = 1
  vpc_security_group_ids          = flatten(local.security_group_ids)
  allowed_cidr_blocks             = []
  instance_type                   = lookup(var.alf_rds_props, "aurora_instance_class", "db.r5.large")
  storage_encrypted               = true
  apply_immediately               = true
  monitoring_interval             = 10
  enabled_cloudwatch_logs_exports = ["postgresql"]
  preferred_maintenance_window    = lookup(var.alf_rds_props, "maintenance_window", "wed:19:30-wed:21:30")
  preferred_backup_window         = lookup(var.alf_rds_props, "backup_window", "02:00-04:00")
  tags                            = local.tags
  replica_scale_enabled           = true
  replica_scale_min               = lookup(var.alf_rds_props, "replica_scale_min", 1)
  replica_scale_max               = lookup(var.alf_rds_props, "replica_scale_max", 3)
  copy_tags_to_snapshot           = true
  backup_retention_period         = var.alf_data_import == "enabled" ? 0 : lookup(var.alf_rds_props, "backup_retention_period", 28)
}
