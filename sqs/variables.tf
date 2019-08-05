variable "region" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alf_sqs_backup_config" {
  type = "map"

  default = {
    poll_interval = 10
    image         = "mojdigitalstudio/hmpps-elasticsearch-manager:0.0.267-alpha"
  }
}
