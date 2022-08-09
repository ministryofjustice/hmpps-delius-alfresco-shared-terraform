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

variable "alfresco_content_props" {
  type = map(string)
  default = {
    cpu             = "1024"
    memory          = "4096"
    app_port        = "8080"
    heap_size       = "1500"
    image_url       = "895523100917.dkr.ecr.eu-west-2.amazonaws.com/hmpps/alfresco-content"
    ssm_prefix      = "/alfresco/ecs"
    desired_count   = "1"
    cookie_duration = "3600"
  }
}

variable "alfresco_content_configs" {
  type    = map(string)
  default = {}
}

variable "alfresco_content_image_version" {
  description = "alfresco-content container image version. Supplied through hmpps-alfresco-infra-versions repository or the .env file locally."
  type    = string
  default = "latest"
}

variable "alf_stop_services" {
  type    = string
  default = "no"
}

# Config map in hmpps-delius-alfresco-shared-terraform/configs/alfresco.tfvars
variable "alf_config_map" {
  type    = map(string)
  default = {}
}

variable "alf_push_to_cloudwatch" {
  default = "no"
}
