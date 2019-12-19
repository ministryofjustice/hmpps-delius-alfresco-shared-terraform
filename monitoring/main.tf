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
  region                     = "${var.region}"
  application                = "${data.terraform_remote_state.common.alfresco_app_name}"
  common_name                = "${data.terraform_remote_state.common.short_environment_identifier}-${local.application}"
  tags                       = "${data.terraform_remote_state.common.common_tags}"
  config-bucket              = "${data.terraform_remote_state.common.common_s3-config-bucket}"
  account_id                 = "${data.terraform_remote_state.common.common_account_id}"
  db_instance_id             = "${data.terraform_remote_state.rds.rds_db_instance_id}"
  load_balancer_name         = "${data.terraform_remote_state.asg.asg_elb_name}"
  alarm_period               = 300
  evaluation_periods         = "1"
  alert_suffix               = "alert"
  cpu_alert_threshold        = 70
  warning_suffix             = "warning"
  cpu_warning_threshold      = 60
  critical_suffix            = "critical"
  cpu_critical_threshold     = 80
  db_conn_warning_threshold  = 200
  db_conn_alert_threshold    = 400
  db_conn_critical_threshold = 600
  support_team               = "AWS Delius Support or Zaizzi Teams"
  inst_critical_threshold    = "${var.alfresco_asg_props["asg_min"]}"
  inst_alert_threshold       = "${var.alfresco_asg_props["min_elb_capacity"]}"
  messaging_status           = "${var.alf_ops_alerts["messaging_status"]}"
}
