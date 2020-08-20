variable "lb_name" {
}

variable "internal" {
  default = "true"
}

variable "subnet_ids" {
  type = list(string)
}

variable "enable_deletion_protection" {
  default = "false"
}

variable "security_groups" {
  type = list(string)
}

variable "s3_bucket_name" {
}

variable "logs_enabled" {
  default = "true"
}

variable "load_balancer_type" {
  default = "application"
}

variable "tags" {
  type = map(string)
}

