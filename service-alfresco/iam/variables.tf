variable "environment_identifier" {}

variable "alfresco_app_name" {}

variable "ec2_policy_file" {}

variable "ec2_role_policy_file" {}

variable "ec2_internal_policy_file" {}

variable "tags" {
  type = "map"
}

variable "s3-config-bucket" {}

variable "aws_ecr_arn" {}

variable "remote_iam_role" {}

variable "remote_config_bucket" {}

variable "storage_s3bucket" {}

variable depends_on {
  default = []
  type    = "list"
}
