variable "tags" {
  type = "map"
}

variable "environment_identifier" {
  default = "efs"
}

variable "kms_key_id" {
  default = ""
}

variable "encrypted" {
  default = false
}

variable "performance_mode" {
  default = "generalPurpose"
}

variable "throughput_mode" {
  default = "bursting"
}

variable "share_name" {}

variable "zone_id" {}

variable "domain" {}

variable "security_groups" {
  type = "list"
}

variable "subnets" {
  type = "list"
}
