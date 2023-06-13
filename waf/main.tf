terraform {
  backend "s3" {
  }
}

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

#-------------------------------------------------------------
### Getting the asg details
#-------------------------------------------------------------
data "terraform_remote_state" "lb" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/app-external-load-balancer/terraform.tfstate"
    region = var.region
  }
}

# locals

locals {
  load_balancer_id     = data.terraform_remote_state.lb.outputs.info["arn"]
  application          = data.terraform_remote_state.common.outputs.alfresco_app_name
  common_name          = "${data.terraform_remote_state.common.outputs.short_environment_identifier}-${local.application}"
  tags                 = data.terraform_remote_state.common.outputs.common_tags
  firehose_stream_name = "aws-waf-logs-${local.application}"
  web_acl_name         = "AlfNomsSearchWebACL"
}

