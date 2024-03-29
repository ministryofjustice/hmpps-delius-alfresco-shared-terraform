variable "region" {
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "short_environment_identifier" {
  description = "short resource label or name"
}

variable "alf_alarms_enabled" {
  default = true
}

variable "alf_cloudwatch_log_retention" {
  default = 7
}

variable "environment_name" {
  type = string
}

variable "alf_ops_alerts" {
  type = map(string)
  default = {
    slack_channel_name  = "delius-alerts-alfresco-nonprod"
    log_level           = "info"
    messaging_status    = "disabled"
    runtime             = "python3.9"
    ssm_token           = "manual-ops-alerts-slack-token"
    datapoints_to_alarm = "1"
  }
}

#ASG
variable "alfresco_asg_props" {
  type = map(string)
  default = {
    asg_min          = 1
    min_elb_capacity = 1
  }
}

