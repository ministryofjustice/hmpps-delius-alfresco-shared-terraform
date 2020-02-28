variable "common_name" {}

variable "ec2_policy_file" {}

variable "ec2_internal_policy_file" {}

variable "tags" {
  type = "map"
}

variable "s3-config-bucket" {}

variable "remote_iam_role" {}

variable "remote_config_bucket" {}

variable "storage_s3bucket" {}

variable "s3bucket_kms_arn" {}

variable depends_on {
  default = []
  type    = "list"
}

variable "asg_ssm_arns_map" {
  type    = "map"
  default = {}
}

variable "alf_backups_bucket_arn" {
  default = ""
}
