terraform {
  # The configuration for this backend will be filled in by Terragrunt
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {
  }
}

####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################
#-------------------------------------------------------------
### Getting the common details
#-------------------------------------------------------------
data "terraform_remote_state" "common" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/common/terraform.tfstate"
    region = var.region
  }
}
resource "random_id" "id" {
  byte_length = 8
}

#-------------------------------------------------------------
### Getting the s3 details
#-------------------------------------------------------------
data "terraform_remote_state" "s3bucket" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/s3buckets/terraform.tfstate"
    region = var.region
  }
}

####################################################
# Locals
####################################################

locals {
  account_id         = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id             = data.terraform_remote_state.common.outputs.vpc_id
  public_zone_id     = data.terraform_remote_state.common.outputs.public_zone_id
  app_name           = "alf-external"
  external_domain    = data.terraform_remote_state.common.outputs.external_domain
  dns_hostname       = format("%s.%s", local.app_name, local.external_domain)
  common_name        = format("%s-%s", data.terraform_remote_state.common.outputs.short_environment_identifier, local.app_name)
  region             = var.region
  tags               = data.terraform_remote_state.common.outputs.common_tags
  subnet_ids         = data.terraform_remote_state.common.outputs.public_subnet_ids
  identifier         = "alfresco-${random_id.id.hex}"
  access_logs_bucket = data.terraform_remote_state.common.outputs.common_s3_lb_logs_bucket
}
