terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.16"
}

####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################
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

#-------------------------------------------------------------
### Getting the asg details
#-------------------------------------------------------------
data "terraform_remote_state" "elk" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/elk-migration/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the rds details
#-------------------------------------------------------------
data "terraform_remote_state" "rds" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/database/terraform.tfstate"
    region = "${var.region}"
  }
}

# ssm parameter
data "aws_ssm_parameter" "ssm_token" {
  name = "${var.alf_ops_alerts["ssm_token"]}"
}

####################################################
# Locals
####################################################

locals {
  region           = "${var.region}"
  application      = "${data.terraform_remote_state.common.alfresco_app_name}"
  common_name      = "${data.terraform_remote_state.common.short_environment_identifier}-${local.application}"
  tags             = "${data.terraform_remote_state.common.common_tags}"
  account_id       = "${data.terraform_remote_state.common.common_account_id}"
  db_instance_id   = "${data.terraform_remote_state.rds.rds_db_instance_id}"
  load_balancer_id = "${data.terraform_remote_state.asg.asg_elb_name}"
  alarm_period     = 300
}
