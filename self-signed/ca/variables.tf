variable "region" {
  description = "The AWS region."
}

variable "environment_identifier" {
  description = "resource label or name"
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "self_signed_ca_algorithm" {}

variable "self_signed_ca_rsa_bits" {
  default = 1024
}

variable "self_signed_ca_validity_period_hours" {}

variable "self_signed_ca_early_renewal_hours" {}

variable "is_ca_certificate" {
  default = false
}

variable "alfresco_app_name" {}
