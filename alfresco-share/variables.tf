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

variable "alfresco_share_props" {
  type = map(string)
  default = {
    cpu               = "1024"
    memory            = "4096"
    app_port          = "8080"
    alfresco_port     = "8080"
    target_group_port = "8070"
    image_url         = "895523100917.dkr.ecr.eu-west-2.amazonaws.com/hmpps/alfresco-share"
    desired_count     = "1"
    cookie_duration   = "3600"
    ssm_prefix        = "/alfresco/ecs"
  }
}

variable "alfresco_share_configs" {
  type    = map(string)
  default = {}
}

variable "alfresco_share_image_version" {
  description = "alfresco-share container image version. Supplied through hmpps-alfresco-infra-versions repository or the .env file locally."
  type    = string
  default = "latest"
}

variable "alf_stop_services" {
  type    = string
  default = "no"
}

variable "alf_config_map" {
  type    = map(string)
  default = {}
}

variable "alf_push_to_cloudwatch" {
  default = "no"
}
