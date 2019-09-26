# RDS
variable "region" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alf_rds_props" {
  type = "map"
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
    engine_version          = "9.6.9"
  }
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
    }
  ]
}

# checkpoint_segments
variable "alf_rds_migration_parameters" {
  type    = "list"
  default = []
}
