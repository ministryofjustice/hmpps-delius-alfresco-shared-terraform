variable "prefix" {
  type    = string
  default = "solr"
}

variable "availability_zone" {
  type = string
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

variable "ebs_temp_type" {
  type    = string
  default = "gp2"
}

variable "ebs_temp_size" {
  default = 50
}

variable "ebs_temp_iops" {
  default = 0
}

variable "tags" {
  type = map(string)
}
