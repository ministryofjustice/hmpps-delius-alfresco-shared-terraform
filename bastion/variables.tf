variable "region" {}

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
  default = "t2.small"
}

# ELasticsearch snapshot name
variable "es_snapshot_name" {
  default = "snapshot_1"
}
