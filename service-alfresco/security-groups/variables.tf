variable "environment_identifier" {}
variable "region" {}

variable "alfresco_app_name" {}

variable "role_arn" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alb_http_port" {}

variable "alb_https_port" {}

variable "allowed_ip_cidr" {
  type = "list"
}

# Alfresco ports 21 137 138 139 445 7070 8009 8080
variable "alb_backend_port" {}

variable "alfresco_ftp_port" {}

variable "alfresco_smb_port_start" {}

variable "alfresco_smb_port_end" {}

variable "alfresco_smb_port" {}

variable "alfresco_arcp_port" {}

variable "alfresco_apache_jserv" {}

