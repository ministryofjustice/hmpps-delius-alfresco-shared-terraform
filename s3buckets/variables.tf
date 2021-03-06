variable "region" {
}

variable "environment_type" {
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alf_backups_config" {
  type = map(string)
  default = {
    transition_days                            = 7
    expiration_days                            = 14
    noncurrent_version_transition_days         = 30
    noncurrent_version_transition_glacier_days = 60
    noncurrent_version_expiration_days         = 2560
  }
}

variable "alf_backups_map" {
  type    = map(string)
  default = {}
}
