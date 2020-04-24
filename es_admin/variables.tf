variable "region" {}

variable "role_arn" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "cloudwatch_log_retention" {}

variable "bastion_inventory" {
  default = "dev"
}

variable "environment_name" {}

# Elasticsearch

variable "es_admin_instance_type" {
  default = "t2.large"
}

# ELasticsearch snapshot name
variable "es_snapshot_name" {
  default = "snapshot_1"
}

variable "es_s3_repo_name" {
  default = "alfresco_s3_repo"
}

# Restore mode
variable "alf_restore_status" {
  default = "no-restore"
}

variable "availability_zone" {
  description = "List of the three AZs we want to use"
  type        = "map"
}

variable "es_admin_volume_props" {
  type = "map"
  default {
    size            = 1000
    type            = "gp2"
    iops            = 100
    encrypted       = true
    device_name     = "/dev/xvdb"
    create_snapshot = false
  }
}

variable "alf_cloudwatch_log_retention" {}

variable "metrics_granularity" {
  default = "1Minute"
}

variable "enabled_metrics" {
  type = "list"
  default = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]
}

variable "source_code_versions" {
  type = "map"
  default = {
    esadmin = "master"
  }
}
