variable "log_group_path" {
  description = "resource label or name"
}

variable "loggroupname" {
}

variable "cloudwatch_log_retention" {
}

variable "kms_key_id" {
  default = ""
}

variable "tags" {
  type = map(string)
}

