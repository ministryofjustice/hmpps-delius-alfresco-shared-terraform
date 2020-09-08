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
  type        = map(string)
}

variable "alf_elk_service_props" {
  type = map(string)
  default = {
    elasticsearch_version         = "6.8"
    instance_type                 = "t2.medium.elasticsearch"
    automated_snapshot_start_hour = 23
    encrypt_at_rest               = false
  }
}

variable "alf_cloudwatch_log_retention" {
}
