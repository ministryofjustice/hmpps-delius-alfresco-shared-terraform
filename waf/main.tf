terraform {
  backend "s3" {}
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.16"
}

#-------------------------------------------------------------
### Getting the common details
#-------------------------------------------------------------
data "terraform_remote_state" "common" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/common/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the asg details
#-------------------------------------------------------------
data "terraform_remote_state" "asg" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/asg/terraform.tfstate"
    region = "${var.region}"
  }
}

# locals

locals {
  load_balancer_id     = "${data.terraform_remote_state.asg.asg_elb_id}"
  application          = "${data.terraform_remote_state.common.alfresco_app_name}"
  common_name          = "${data.terraform_remote_state.common.short_environment_identifier}-${local.application}"
  tags                 = "${data.terraform_remote_state.common.common_tags}"
  firehose_stream_name = "aws-waf-logs-${local.application}"
  web_acl_name         = "AlfNomsSearchWebACL"
}
