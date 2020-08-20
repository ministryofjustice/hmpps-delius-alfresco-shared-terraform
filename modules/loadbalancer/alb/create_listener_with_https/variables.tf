variable "lb_port" {
}

variable "lb_protocol" {
}

variable "lb_arn" {
}

variable "ssl_policy" {
  default = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "certificate_arn" {
  type = list(string)
}

variable "target_group_arn" {
}

