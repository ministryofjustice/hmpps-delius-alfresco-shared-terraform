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

variable "alfresco_proxy_props" {
  type = map(string)
  default = {
    cpu                   = "1024"
    memory                = "2048"
    app_port              = "80"
    image_url             = "895523100917.dkr.ecr.eu-west-2.amazonaws.com/hmpps/alfresco-proxy"
    version               = "0.1.0"
    desired_count         = "1"
    cookie_duration       = "3600"
    health_check_endpoint = "/h3alth/checkz"
    ssl_policy            = "ELBSecurityPolicy-TLS-1-2-2017-01"
  }
}

variable "alfresco_proxy_configs" {
  type    = map(string)
  default = {}
}

variable "user_access_cidr_blocks" {
  type = list(string)
}

variable "alfresco_access_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "alf_push_to_cloudwatch" {
  default = "no"
}
