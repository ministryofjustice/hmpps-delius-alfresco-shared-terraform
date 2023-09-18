###############################################
# CloudWatch
###############################################
module "create_loggroup" {
  source                   = "../modules/cloudwatch/loggroup"
  log_group_path           = local.common_name
  loggroupname             = local.application_name
  cloudwatch_log_retention = var.alf_cloudwatch_log_retention
  kms_key_id               = local.logs_kms_arn
  tags                     = local.tags
}

#------------------------------------------------------------------------------------------------------------------
# CloudWatch Log - Cleanup Scheduler
#------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "cleanup_scheduler" {
  name              = local.cleanup_scheduler_log_group
  retention_in_days = var.alf_cloudwatch_log_retention
  tags = merge(
    local.tags,
    {
      "Name" = local.cleanup_scheduler_log_group
    },
  )
}

#------------------------------------------------------------------------------------------------------------------
# Lambda Alert - Cleanup Scheduler
#------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "lambda_errors_alert" {
  alarm_name          = "${var.environment_identifier}__cleanup_scheduler__alert__scheduler_Errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This alarm returns any Cleanup Scheduler Lambda Errors. For more details about the error(s) found, please review log group ${local.cleanup_scheduler_log_group}"
  alarm_actions       = [local.sns_topic_arn]
  ok_actions          = [local.sns_topic_arn]
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"
  tags                = local.tags
  dimensions = {
    FunctionName = aws_lambda_function.ebs-vols-cleanup-scheduler.function_name
    Resource     = aws_lambda_function.ebs-vols-cleanup-scheduler.function_name
  }
}
