variable "tags" {
  type = map(string)
}

variable "ecs_config" {
  type = map(string)
  default = {
    name                = "ecs_cluster"
    cluster             = "cluster id"
    account_id          = "account_id"
    region              = "eu-west-2"
    log_group_arn       = "arn"
    storage_bucket_name = "bucket name"
    storage_bucket_arn  = "arn"
    storage_kms_arn     = "kms arn"
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
