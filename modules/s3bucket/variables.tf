variable "common_name" {}

variable "tags" {
  type = "map"
}

variable "s3cloudtrail_policy_file" {}

variable "s3_lifecycle_config" {
  type = "map"
  default = {
    noncurrent_version_transition_days         = 30
    noncurrent_version_transition_glacier_days = 60
    noncurrent_version_expiration_days         = 90
  }
}

