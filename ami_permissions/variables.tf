variable "region" {
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

# configs/alfresco.tfvars
variable "alf_config_map" {
  type    = map(string)
  default = {}
}

# configs/alfresco.tfvars
variable "solr_config_map" {
  type    = map(string)
  default = {}
}
