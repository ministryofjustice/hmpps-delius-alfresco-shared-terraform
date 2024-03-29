variable "environment_identifier" {
}

variable "environment_name" {
}

variable "region" {
}

variable "alfresco_app_name" {
}

variable "alb_http_port" {
}

variable "alb_https_port" {
}

# Alfresco ports 21 137 138 139 445 7070 8009 8080
variable "alb_backend_port" {
}

variable "alfresco_ftp_port" {
}

variable "alfresco_smb_port_start" {
}

variable "alfresco_smb_port_end" {
}

variable "alfresco_smb_port" {
}

variable "alfresco_arcp_port" {
}

variable "alfresco_apache_jserv" {
}

variable "vpc_id" {
}

variable "allowed_cidr_block" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "common_name" {
}

variable "public_cidr_block" {
  type = list(string)
}

variable "private_cidr_block" {
  type = list(string)
}

variable "db_cidr_block" {
  type = list(string)
}

# SG ids
variable "sg_map_ids" {
  type = map(string)
}

variable "bastion_cidr" {
  type = map(string)
}
