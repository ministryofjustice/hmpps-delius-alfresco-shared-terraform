variable "region" {
  description = "The AWS region."
}

variable "environment_identifier" {
  description = "resource label or name"
}

variable "self_signed_server_algorithm" {}

variable "self_signed_server_rsa_bits" {
  default = 1024
}

variable "self_signed_server_validity_period_hours" {}

variable "self_signed_server_early_renewal_hours" {}

variable "alfresco_app_name" {}

variable "internal_domain" {}

variable "common_name" {}

variable "tags" {
  type = "map"
}

variable "ca_private_key_pem" {}
variable "ca_cert_pem" {}

# Dependency
variable depends_on {
  default = []
  type    = "list"
}
