# RDS
variable "region" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

#ASG
variable "alfresco_asg_props" {
  type = "map"
  default = {
    asg_desired               = 1
    asg_min                   = 1
    asg_max                   = 2
    asg_instance_type         = "m4.xlarge"
    asg_ami                   = "ami-0d891eb6bea9cfa8c"
    ebs_volume_size           = 512
    health_check_grace_period = 900
  }
}

variable "alf_metrics_props" {
  type = "map"
  default = {
    metrics_granularity = "1Minute"
    enabled_metrics = [
      "GroupMinSize",
      "GroupMaxSize",
      "GroupDesiredCapacity",
      "GroupInServiceInstances",
      "GroupPendingInstances",
      "GroupStandbyInstances",
      "GroupTerminatingInstances",
      "GroupTotalInstances"
    ]
  }
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

variable "alfresco_volume_size" {
  default = 20
}
