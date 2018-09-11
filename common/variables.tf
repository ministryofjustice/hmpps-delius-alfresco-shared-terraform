variable "environment_identifier" {
  description = "resource label or name"
}

variable "short_environment_identifier" {
  description = "short resource label or name"
}

variable "region" {
  description = "The AWS region."
}

variable "environment" {
  description = "environment"
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "s3_lb_policy_file" {}

variable "lb_account_id" {}

variable "role_arn" {}

variable "route53_hosted_zone_id" {}

variable "alfresco_app_name" {}

variable "vpc_id" {}
variable "cidr_block" {}
variable "internal_domain" {}

variable "tags" {
  type = "map"
}

variable "common_name" {}
