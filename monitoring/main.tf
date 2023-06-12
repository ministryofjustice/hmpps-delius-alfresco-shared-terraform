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
  allocated_storage             = data.terraform_remote_state.rds.outputs.info.allocated_storage
  max_allocated_storage         = data.terraform_remote_state.rds.outputs.info.max_allocated_storage
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

  # threshold for database storage alert is 10% of allocated storage or 10% of max allocated storage if max allocated storage is set
  database_storage_alert_threshold = local.max_allocated_storage > 0 ? local.max_allocated_storage * 0.1 : local.allocated_storage * 0.1
}
