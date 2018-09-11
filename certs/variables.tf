# Common variables
variable "environment_identifier" {
  description = "resource label or name"
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

variable "alfresco_app_name" {}

# self signed ca
variable "self_signed_ca_algorithm" {}

variable "self_signed_ca_rsa_bits" {
  default = 1024
}

variable "self_signed_ca_validity_period_hours" {}

variable "self_signed_ca_early_renewal_hours" {}

# self signed server
variable "self_signed_server_algorithm" {}

variable "self_signed_server_rsa_bits" {}

variable "self_signed_server_validity_period_hours" {}

variable "self_signed_server_early_renewal_hours" {}
