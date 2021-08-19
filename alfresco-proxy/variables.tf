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
    cpu                   = "500"
    memory                = "2048"
    app_port              = "80"
    image_url             = "nginx"
    version               = "1.19"
    desired_count         = "1"
    cookie_duration       = "3600"
    health_check_endpoint = "/h3alth/checkz"
  }
}

variable "alfresco_proxy_configs" {
  type    = map(string)
  default = {}
}
