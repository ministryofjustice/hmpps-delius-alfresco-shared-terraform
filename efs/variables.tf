# RDS
variable "region" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alf_backups_config" {
  type = "map"
  default = {
    provisioned_throughput_in_mibps = 10
    throughput_mode                 = "provisioned"
  }
}
