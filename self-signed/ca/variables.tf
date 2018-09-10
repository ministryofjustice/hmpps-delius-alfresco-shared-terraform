variable "region" {
  description = "The AWS region."
}

variable "environment_identifier" {
  description = "resource label or name"
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

variable "internal_domain" {}

variable "common_name" {}

variable "tags" {
  type = "map"
}

variable depends_on {
  default = []
  type    = "list"
}
