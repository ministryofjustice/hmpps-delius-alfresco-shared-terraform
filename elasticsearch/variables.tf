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

variable "es_discovery_type" {
  default = "single-node"
}

variable "es_java_opts" {
  default = "-Xms8g -Xmx8g -Des.enforce.bootstrap.checks=true"
}

variable "es_ecs_memory" {
  default = "12000"
}

variable "es_ecs_cpu_units" {
  default = "500"
}

variable "es_ecs_mem_limit" {
  default = "11500"
}

variable "es_image_url" {
  default = "elasticsearch:5.6"
}

variable "es_service_desired_count" {
  default = 1
}

variable "es_ebs_volume_size" {
  default = 200
}

variable "es_instance_type" {
  default = "t2.xlarge"
}

#LB
variable "cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  default     = true
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  default     = 60
}

variable "connection_draining" {
  description = "Boolean to enable connection draining"
  default     = false
}

variable "connection_draining_timeout" {
  description = "The time in seconds to allow for connections to drain"
  default     = 300
}

variable "access_logs" {
  description = "An access logs block"
  type        = "list"
  default     = []
}
