# Common variables
variable "eng_remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "eng_role_arn" {
}

variable "environment_identifier" {
  description = "resource label or name"
}

variable "short_environment_identifier" {
  description = "short resource label or name"
}

variable "region" {
  description = "The AWS region."
}

variable "environment_type" {
  description = "environment"
}

variable "environment_name" {
}

variable "project_name" {
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "lb_account_id" {
}

variable "role_arn" {
}

variable "route53_hosted_zone_id" {
}

variable "alfresco_app_name" {
}

# self signed ca
variable "self_signed_ca_algorithm" {
}

variable "self_signed_ca_rsa_bits" {
  default = 1024
}

variable "self_signed_ca_validity_period_hours" {
}

variable "self_signed_ca_early_renewal_hours" {
}

# self signed server
variable "self_signed_server_algorithm" {
}

variable "self_signed_server_rsa_bits" {
}

variable "self_signed_server_validity_period_hours" {
}

variable "self_signed_server_early_renewal_hours" {
}

# RDS
variable "rds_instance_class" {
}

variable "rds_allocated_storage" {
}

variable "alfresco_instance_ami" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}


variable "bastion_role_arn" {
  description = "arn to use for bastion terraform"
}

variable "bastion_remote_state_bucket_name" {
  description = "Terraform remote state bucket name for bastion vpc"
}
