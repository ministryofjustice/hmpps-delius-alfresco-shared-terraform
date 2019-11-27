variable "region" {}

variable "alf_iam_cross_account_perms" {
  default = false
}


variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "eng_remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "eng_role_arn" {}

variable "oracle_db_operation" {
  type    = "map"
  default = {}
}

variable "is_production" {
  default = false
}

variable "alf_backups_config" {
  type = "map"
  default = {
    prod_backups_bucket = ""
    prod_kms_key_arn    = ""

  }
}
