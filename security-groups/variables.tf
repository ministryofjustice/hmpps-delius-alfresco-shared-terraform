variable "region" {
}

variable "environment_name" {
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alb_http_port" {
  default = 80
}

variable "alb_https_port" {
  default = 443
}

# Alfresco ports 21 137 138 139 445 7070 8009 8080
variable "alb_backend_port" {
  default = 8080
}

variable "alfresco_ftp_port" {
  default = 21
}

variable "alfresco_smb_port_start" {
  default = 137
}

variable "alfresco_smb_port_end" {
  default = 139
}

variable "alfresco_smb_port" {
  default = 445
}

variable "alfresco_arcp_port" {
  default = 7070
}

variable "alfresco_apache_jserv" {
  default = 8009
}

variable "user_access_cidr_blocks" {
  type = list(string)
}

variable "alfresco_access_cidr_blocks" {
  type    = list(string)
  default = []
}

