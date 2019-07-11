variable "common_name" {}

variable "ec2_policy_file" {}

variable "ecs_policy_file" {}

variable "ecs_role_policy_file" {}

variable "ec2_role_policy_file" {}

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

variable "restore_dynamodb_table_arn" {}
