variable "region" {
}

variable "role_arn" {
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "cloudwatch_log_retention" {
}

variable "bastion_inventory" {
  default = "dev"
}

variable "environment_name" {
}

variable "availability_zone" {
  description = "List of the three AZs we want to use"
  type        = map(string)
}

variable "alf_elk_service_props" {
  type = map(string)
  default = {
    elasticsearch_version         = "6.8"
    instance_type                 = "t3.medium.elasticsearch"
    automated_snapshot_start_hour = 23
    encrypt_at_rest               = true
    snapshot_unit_count           = 28
    indices_unit_count            = 30
    backup_units_count            = 2
    delete_schedule               = "30 3 * * ? *"
    snapshot_schedule             = "30 21 * * ? *"
    domain_name_type              = "full"
  }
}

variable "alf_elk_service_map" {
  type    = map(string)
  default = {}
}


variable "alf_cloudwatch_log_retention" {}

variable "alf_cognito_map" {
  type    = map(string)
  default = {}
}

variable "metrics_granularity" {
  default = "1Minute"
}

variable "health_check_type" {
  default = "ELB"
}

variable "enabled_metrics" {
  type = list(string)
  default = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]
}

variable "termination_policies" {
  type    = list(string)
  default = ["OldestInstance", "OldestLaunchTemplate", "OldestLaunchConfiguration"]
}

variable "user_access_cidr_blocks" {
  type = list(string)
}

variable "elasticsearch_props" {
  type    = map(string)
  default = {}
}
