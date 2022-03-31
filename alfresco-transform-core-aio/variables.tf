# Common variables
variable "environment_identifier" {
  description = "resource label or name"
}

variable "region" {
  description = "The AWS region."
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alf_cloudwatch_log_retention" {
}

variable "alfresco_transform_core_aio_props" {
  type = map(string)
  default = {
    cpu             = "2048"
    memory          = "8192"
    app_port        = "8090"
    image_url       = "alfresco/alfresco-transform-core-aio"
    version         = "2.5.2"
    java_opts       = ""
    desired_count   = "1"
    cookie_duration = "3600"
  }
}

variable "alfresco_transform_core_aio_configs" {
  type    = map(string)
  default = {}
}

variable "alf_stop_services" {
  type    = string
  default = "no"
}

variable "alf_push_to_cloudwatch" {
  default = "no"
}
