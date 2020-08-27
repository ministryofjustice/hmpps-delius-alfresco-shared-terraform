variable "region" {
}

variable "alfresco_asg_props" {
  type = map(string)
  default = {
    image_id = "" # used for updating ami launch permissions
  }
}

variable "environment_name" {
  type = string
}

variable "alf_account_ids" {
  type = map(string)
  default = {
    hmpps-alfresco-dev = "563502482979"
  }
}

