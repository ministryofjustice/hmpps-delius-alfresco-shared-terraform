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

#-------------------------------------------------------------
### Getting the asg details
#-------------------------------------------------------------
data "terraform_remote_state" "asg" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/asg/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "elk-service" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/elk-service/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the rds details
#-------------------------------------------------------------
data "terraform_remote_state" "rds" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/database/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the asg details
#-------------------------------------------------------------
data "terraform_remote_state" "solr" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/solr/terraform.tfstate"
    region = var.region
  }
}

# ssm parameter
data "aws_ssm_parameter" "ssm_token" {
  name = var.alf_ops_alerts["ssm_token"]
}

# getting lb details
data "aws_lb" "asg_lb" {
  arn = data.terraform_remote_state.asg.outputs.asg_elb_id
}

# target group
data "aws_lb_target_group" "asg_target_group" {
  name = "${data.terraform_remote_state.common.outputs.short_environment_identifier}-alf-app"
}

# getting lb details
data "aws_lb" "solr_lb" {
  arn = data.terraform_remote_state.solr.outputs.alb_id
}

# target group
data "aws_lb_target_group" "solr_target_group" {
  name = "${data.terraform_remote_state.common.outputs.short_environment_identifier}-solr"
}

####################################################
# Locals
####################################################

locals {
  region                        = var.region
  application                   = data.terraform_remote_state.common.outputs.alfresco_app_name
  common_name                   = "${data.terraform_remote_state.common.outputs.short_environment_identifier}-${local.application}"
  tags                          = data.terraform_remote_state.common.outputs.common_tags
  config-bucket                 = data.terraform_remote_state.common.outputs.common_s3-config-bucket
  account_id                    = data.terraform_remote_state.common.outputs.common_account_id
  db_instance_id                = data.terraform_remote_state.rds.outputs.info.id
  load_balancer_arn_suffix      = data.aws_lb.asg_lb.arn_suffix
  solr_load_balancer_arn_suffix = data.aws_lb.solr_lb.arn_suffix
  target_group_suffix           = data.aws_lb_target_group.asg_target_group.arn_suffix
  solr_target_group_suffix      = data.aws_lb_target_group.solr_target_group.arn_suffix
  alarm_period                  = 300
  short_alarm_period            = 60
  evaluation_periods            = "1"
  alert_suffix                  = "alert"
  cpu_alert_threshold           = 70
  warning_suffix                = "warning"
  cpu_warning_threshold         = 60
  critical_suffix               = "critical"
  cpu_critical_threshold        = 80
  db_conn_warning_threshold     = 200
  db_conn_alert_threshold       = 400
  db_conn_critical_threshold    = 600
  support_team                  = "AWS Delius Support or Zaizzi Teams"
  inst_critical_threshold       = lookup(var.alfresco_asg_props, "asg_min", 1)
  inst_alert_threshold          = lookup(var.alfresco_asg_props, "min_elb_capacity", 1)
  messaging_status              = lookup(var.alf_ops_alerts, "messaging_status", "disabled")
  datapoints_to_alarm           = lookup(var.alf_ops_alerts, "datapoints_to_alarm", "1")
  elasticsearch_domain          = data.terraform_remote_state.elk-service.outputs.elk_service["domain_name"]
}

