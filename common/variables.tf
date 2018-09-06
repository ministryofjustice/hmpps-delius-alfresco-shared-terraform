variable "environment_identifier" {
  description = "resource label or name"
}

variable "short_environment_identifier" {
  description = "short resource label or name"
}

variable "region" {
  description = "The AWS region."
}

variable "route53_domain_private" {}

variable "tags" {
  type = "map"
}

variable "s3_lb_policy_file" {}

variable "lb_account_id" {}

variable "route53_internal_domain" {}

variable "role_arn" {}

variable "route53_hosted_zone_id" {}

variable "route53_sub_domain" {}

variable "alfresco_app_name" {}
