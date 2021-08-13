variable "prefix" {
  type    = string
  default = "solr"
}

variable "availability_zone" {
  type = string
}

variable "kms_key_id" {
  type = "string"
}

variable "ebs_data_type" {
  type    = string
  default = "gp2"
}

variable "ebs_data_size" {
  default = 50
}

variable "ebs_data_iops" {
  default = 0
}

variable "tags" {
  type = map(string)
}

variable "create" {
  default = 1
}
