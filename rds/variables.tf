# RDS
variable "region" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "rds_instance_class" {}

variable "rds_allocated_storage" {}
