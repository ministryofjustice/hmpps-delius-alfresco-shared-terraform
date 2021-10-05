# RDS
variable "region" {
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alf_cloudwatch_log_retention" {
}

variable "alf_firehose_configs" {
  type = map(string)
  default = {
    index_name = "alfresco_logs"
    index_rotation_period = "OneDay"
  }
}
variable "alf_firehose_overrides" {
  type    = map(string)
  default = {}
}
