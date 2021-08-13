variable "tags" {
  type = map(string)
}

variable "ecs_config" {
  type = map(string)
  default = {
    name                  = "ecs_cluster"
    account_id            = "account_id"
    region                = "eu-west-2"
    log_group_arn         = "arn"
    storage_bucket_name   = "bucket name"
    storage_bucket_arn    = "arn"
    storage_kms_arn       = "kms arn"
    ecs_cluster_name      = "ecs cluster name"
    desired_count         = "1"
    capacity_provider     = "capacity_provider"
    deployment_controller = "ECS"
  }
}

variable "secrets" {
  description = "Map of environment variables that should be pulled from SSM parameter store, as parameter paths."
  type        = map(string)
  default     = {}
}

variable "task_policy_json" {
  description = "Rendered policy for task role"
}

variable "container_definitions" {
  description = "Task definition rendered"
}

variable "security_groups" {
  description = "Security groups to apply to the ECS tasks"
  type        = list(string)
}

variable "subnets_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "ebs_volumes" {
  type = list(object(
    {
      name          = string
      scope         = string
      autoprovision = bool
      driver        = string
      type          = string
      size          = number
      kms_key_id    = string
    }
  ))
  default = []
}
