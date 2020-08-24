# RDS
variable "region" {}

variable "environment_type" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alf_rds_props" {
  type = map(string)
  default = {
    instance_class          = "db.t2.medium"
    iops                    = 10
    storage_type            = "gp2"
    allocated_storage       = 30
    maintenance_window      = "Sun:06:00-Sun:08:00"
    backup_window           = "22:00-00:00"
    backup_retention_period = 28
    family                  = "postgres9.6"
    engine                  = "postgres"
    major_engine_version    = "9.6"
    replica_engine_version  = "9.6.9"
    master_engine_version   = "9.6.9"
  }
}

variable "alf_snapshot_identifier" {
  default = null
}

variable "alf_data_import" {
  default = "disabled"
}

variable "alf_db_parameters" {
  type = "list"
  default = [
    {
      name         = "max_connections"
      value        = "800"
      apply_method = "pending-reboot"
    },
    {
      name         = "shared_preload_libraries"
      value        = "pg_stat_statements"
      apply_method = "pending-reboot"
    },
    {
      name         = "track_activity_query_size"
      value        = "2048"
      apply_method = "pending-reboot"
    },
    {
      name         = "pg_stat_statements.track"
      value        = "ALL"
      apply_method = "pending-reboot"
    },
    {
      name         = "pg_stat_statements.max"
      value        = "10000"
      apply_method = "pending-reboot"
    },
    {
      name         = "log_statement"
      value        = "mod"
      apply_method = "pending-reboot"
    },
    {
      name         = "log_min_duration_statement"
      value        = "5000"
      apply_method = "pending-reboot"
    }
  ]
}

# checkpoint_segments
variable "alf_rds_migration_parameters" {
  type    = "list"
  default = []
}

variable "alf_cloudwatch_log_retention" {}

variable "alf_db_options" {
  type        = "list"
  description = "A list of Options to apply."
  default     = []
}
