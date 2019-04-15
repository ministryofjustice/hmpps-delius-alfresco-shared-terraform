# RDS
variable "region" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

#ASG
variable "az_asg_desired" {
  type = "map"
}

variable "az_asg_max" {
  type = "map"
}

variable "az_asg_min" {
  type = "map"
}

variable "cloudwatch_log_retention" {}

variable "alfresco_instance_ami" {
  type    = "map"
  default = {}
}

variable "asg_instance_type" {
  default = "m5.large"
}

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
