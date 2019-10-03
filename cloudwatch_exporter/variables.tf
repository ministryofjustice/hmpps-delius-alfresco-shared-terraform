variable "region" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alf_lambda_timeout" {
  default = 300
}

variable "cloudwatch_log_retention" {}

variable "alf_cron_expression" {
  default = "30 1 * * ? *"
}
