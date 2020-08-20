variable "appname" {
}

variable "target_port" {
}

variable "target_protocol" {
}

variable "vpc_id" {
}

variable "deregistration_delay" {
  default = "300"
}

variable "target_type" {
}

variable "check_interval" {
}

variable "check_path" {
}

variable "check_port" {
}

variable "check_protocol" {
}

variable "timeout" {
}

variable "healthy_threshold" {
}

variable "unhealthy_threshold" {
}

variable "return_code" {
}

variable "tags" {
  type = map(string)
}

