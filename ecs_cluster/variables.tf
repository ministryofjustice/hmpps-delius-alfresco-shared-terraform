# RDS
variable "region" {
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alf_cloudwatch_log_retention" {
}


variable "alf_ecs_config" {
  type = map(string)
  default = {
    ecs_instance_type             = "m5.xlarge"
    node_max_count                = "5"
    node_min_count                = "2"
    ecs_cluster_target_capacity   = "100"
    ecs_maximum_scaling_step_size = "10"
    ecs_cluster_namespace_name    = "alf_app_ecs.local"
  }
}

variable "alf_config_overrides" {
  type = map(string)
  default = {}
}
