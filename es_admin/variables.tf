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
  default = "elk_s3_repo"
}

# Restore mode
variable "alf_restore_status" {
  default = "no-restore"
}
