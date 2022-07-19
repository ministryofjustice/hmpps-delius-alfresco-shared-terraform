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
    ecs_cluster_name      = "ecs cluster name"
    desired_count         = "1"
    capacity_provider     = "capacity_provider"
    deployment_controller = "ECS"
    namespace_id          = "namespace id"
    grace_period          = "0"
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

variable "subnet_ids" {
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
      iops          = number
    }
  ))
  default = []
}

variable "load_balancer_targets" {
  type = list(object(
    {
      target_group_arn = string
      container_name   = string
      container_port   = number
    }
  ))
  default = []
}

variable "health_check_grace_period_seconds" {
  description = "Healthcheck grace period"
  default     = "0"
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment."
  default     = "100"
}

variable "deployment_maximum_percent" {
  description = "Upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment. Not valid when using the DAEMON scheduling strategy."
  default     = "200"
}
