variable "region" {}

variable "account_id" {}

variable "environment_identifier" {}

variable "short_environment_identifier" {}

variable "common_name" {}

variable "environment" {}

variable "tags" {
  type = "map"
}

variable "app_hostnames" {
  type = "map"
}

variable "certificate_arn" {}

variable "app_name" {}

variable "public_subnet_ids" {
  type = "list"
}

variable "private_subnet_ids" {
  type = "list"
}

variable "instance_security_groups" {
  type = "list"
}

variable "lb_security_groups" {
  type = "list"
}

variable "config_bucket" {}

variable "vpc_id" {}

variable "access_logs_bucket" {}

variable "external_domain" {}

variable "internal_domain" {}

variable "public_zone_id" {}

variable "cloudwatch_log_retention" {}

################ LB SECTION ###############

# ELB
variable "internal" {
  description = "If true, ELB will be an internal ELB"
}

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

variable "health_check" {
  description = "A health check block"
  type        = "list"
}

############### END OF LB SECTION #####################

##################### ASG SECTION #####################
variable "service_desired_count" {}

variable "user_data" {}

variable "ebs_device_name" {}
variable "ebs_volume_type" {}
variable "ebs_volume_size" {}
variable "ebs_encrypted" {}

variable "instance_type" {}

variable "volume_size" {}

variable "asg_desired" {}

variable "asg_max" {}

variable "asg_min" {}

variable "associate_public_ip_address" {}

variable "keys_dir" {}

variable "self_signed_ssm" {
  type = "map"
}

############### END OF ASG SECTION #####################

##################### ECS SECTION #####################

variable "image_url" {}

variable "image_version" {}

variable "backend_ecs_cpu_units" {}

variable "backend_ecs_memory" {}

variable "backend_app_template_file" {}

variable "kibana_host" {}

variable "ecs_service_role" {}

variable "ami_id" {}

variable "instance_profile" {}

variable "ssh_deployer_key" {}
