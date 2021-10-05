# RDS
variable "region" {
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alf_overwrite_ssm_parameter" {
  type        = bool
  default     = false
  description = "Whether to overwrite an existing SSM parameter"
}

variable "alf_ssm_parameter_name_format" {
  type        = string
  default     = "/alfresco/%s/%s"
  description = "SSM parameter name format"
}

variable "use_aws_owned_key" {
  type        = bool
  default     = true
  description = "Boolean to enable an AWS owned Key Management Service (KMS) Customer Master Key (CMK) for Amazon MQ encryption that is not in your account"
}

variable "kms_mq_key_arn" {
  type        = string
  default     = null
  description = "ARN of the AWS KMS key used for Amazon MQ encryption"
}

variable "alfresco_activemq_props" {
  type = map(string)
  default = {
    engine_type        = "ActiveMQ"
    engine_version     = "5.15.14"
    deployment_mode    = "ACTIVE_STANDBY_MULTI_AZ"
    host_instance_type = "mq.t3.micro"
    day_of_week        = "SUNDAY"
    time_of_day        = "02:00"
    time_zone          = "UTC"
  }
}

variable "alfresco_activemq_configs" {
  type    = map(string)
  default = {}
}
