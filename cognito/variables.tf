variable "region" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alf_cognito_map" {
  type = "map"
  default = {
    minimum_length               = 12
    require_symbols              = false
    unused_account_validity_days = 2
  }
}
