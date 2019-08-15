variable "name" {
  description = "The name of the ELB"
}

variable "security_groups" {
  description = "A list of security group IDs to assign to the ELB"
  type        = "list"
}

variable "subnets" {
  description = "A list of subnet IDs to attach to the ELB"
  type        = "list"
}

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

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  default     = {}
}

variable "ssl_certificate_id" {
  description = "ssl_certificate_id"
}

variable "instance_port" {}
variable "instance_protocol" {}
variable "lb_port" {}
variable "lb_port_https" {}
variable "lb_protocol" {}
variable "lb_protocol_https" {}

variable "health_check" {
  description = "A health check block"
  type        = "list"
}

variable "bucket" {
  description = "bucket name"
}

variable "bucket_prefix" {
  description = "Logs prefix"
}

variable "interval" {
  default = 60
}
