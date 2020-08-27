# RDS
variable "region" {
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

# elastiCache
variable "elasticCache_cluster_size" {
  default = 2
}

variable "elastiCache_instance_type" {
  default = "cache.m4.large"
}

variable "elastiCache_engine_version" {
  default     = "1.5.10"
  description = "Engine version"
}

