variable "region" {
}

variable "environment_type" {
  description = "environment"
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "size" {
  description = "active directory size"
  default     = "small"
}

variable "ad_password_length" {
  default = "18"
}

variable "instance_type" {
  default = "t2.medium"
}

variable "bastion_inventory" {
}

variable "cloudwatch_log_retention" {
}

################ LB SECTION ###############

# ELB
variable "internal" {
  description = "If true, ELB will be an internal ELB"
  default     = false
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
  type        = list(string)
  default     = []
}

############### END OF LB SECTION #####################

# PROXY

variable "proxy_instance_type" {
  default = "t2.medium"
}

