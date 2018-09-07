variable "environment_identifier" {}
variable "region" {}

variable "alfresco_app_name" {}

variable "role_arn" {}

variable "eng_role_arn" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "short_environment_identifier" {}

variable "ec2_policy_file" {}

variable "eng-remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}
