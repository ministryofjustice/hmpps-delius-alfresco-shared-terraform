variable "region" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alf_backups_config" {
  type = "map"
  default = {
    transition_days                            = 8
    expiration_days                            = 2560
    noncurrent_version_transition_days         = 30
    noncurrent_version_transition_glacier_days = 60
    noncurrent_version_expiration_days         = 90
  }
}
