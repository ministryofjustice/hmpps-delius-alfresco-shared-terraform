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
    cpu        = "500"
    memory     = "4096"
    port       = "8080"
    image_url  = "895523100917.dkr.ecr.eu-west-2.amazonaws.com/hmpps/alfresco-content"
    version    = "latest"
    ssm_prefix = "/alfresco/ecs"
  }
}

variable "alfresco_content_configs" {
  type    = map(string)
  default = {}
}
