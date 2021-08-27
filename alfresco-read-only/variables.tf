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
    cpu               = "500"
    memory            = "4096"
    app_port          = "8080"
    target_group_port = "9000"
    heap_size         = "1500"
    image_url         = "895523100917.dkr.ecr.eu-west-2.amazonaws.com/hmpps/alfresco-content"
    version           = "R4.1.5"
    ssm_prefix        = "/alfresco/ecs"
    desired_count     = "1"
    cookie_duration   = "3600"
  }
}

variable "alfresco_content_configs" {
  type    = map(string)
  default = {}
}
