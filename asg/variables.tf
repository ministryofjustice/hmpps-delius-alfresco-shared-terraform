# RDS
variable "region" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

#ASG
variable "alfresco_asg_props" {
  type    = "map"
  default = {}
}

variable "cloudwatch_log_retention" {}

variable "bastion_inventory" {
  default = "dev"
}

variable "alfresco_jvm_memory" {
  description = "jvm memmory"
}

variable "spg_messaging_broker_url" {
  default     = "localhost:61616"
  description = "SPG messaging broker url"
}

variable "alf_ebs_volume_size" {
  default = "512"
}
