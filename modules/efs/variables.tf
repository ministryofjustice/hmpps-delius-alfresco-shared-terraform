variable "tags" {
  type = map(string)
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

variable "provisioned_throughput_in_mibps" {
  default = 0
}

variable "throughput_mode" {
  default = "bursting"
}

variable "share_name" {
}

variable "zone_id" {
}

variable "domain" {
}

variable "security_groups" {
  type = list(string)
}

variable "subnets" {
  type = list(string)
}

