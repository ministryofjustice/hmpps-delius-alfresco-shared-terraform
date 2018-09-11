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
  default = "t2.medium"
}
