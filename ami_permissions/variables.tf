variable "region" {}

variable "alfresco_asg_props" {
  type = "map"
  default = {
    image_id = "" # used for updating ami launch permissions
  }
}

variable "environment_name" {
  type = "string"
}

variable "alf_account_ids" {
  type = "map"
  default = {
    hmpps-alfresco-dev = "563502482979"
  }
}
