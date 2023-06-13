resource "aws_cloudwatch_metric_alarm" "db_cpu_critical" {
  alarm_name          = "${local.application}_database_cpu_${local.critical_suffix}"
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = local.alarm_period
  statistic           = "Average"
  threshold           = local.cpu_critical_threshold
  alarm_description   = "Database CPU averaging over ${local.cpu_critical_threshold}, possible outage event. Please contact ${local.support_team}"
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  datapoints_to_alarm = local.datapoints_to_alarm

  dimensions = {
    DBInstanceIdentifier = local.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "db_cpu_alert" {
  alarm_name          = "${local.application}_database_cpu_${local.alert_suffix}"
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = local.alarm_period
  statistic           = "Average"
  threshold           = local.cpu_alert_threshold
  alarm_description   = "Database CPU averaging over ${local.cpu_alert_threshold}, if database connection alerts are getting raised as well. Please contact ${local.support_team}"
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  datapoints_to_alarm = local.datapoints_to_alarm

  dimensions = {
    DBInstanceIdentifier = local.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "db_cpu_warning" {
  alarm_name          = "${local.application}_database_cpu_${local.warning_suffix}"
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = local.alarm_period
  statistic           = "Average"
  threshold           = local.cpu_warning_threshold
  alarm_description   = "Database CPU averaging over ${local.cpu_warning_threshold}, check for database connection alerts."
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  datapoints_to_alarm = local.datapoints_to_alarm

  dimensions = {
    DBInstanceIdentifier = local.db_instance_id
  }
}

###

resource "aws_cloudwatch_metric_alarm" "db_connections_warning" {
  alarm_name          = "${local.application}_database_connections_${local.warning_suffix}"
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.evaluation_periods
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = local.alarm_period
  statistic           = "Average"
  threshold           = local.db_conn_warning_threshold
  alarm_description   = "Average database connections over ${local.db_conn_warning_threshold}, check for database CPU alerts"
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  datapoints_to_alarm = local.datapoints_to_alarm

  dimensions = {
    DBInstanceIdentifier = local.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "db_connections_alert" {
  alarm_name          = "${local.application}_database_connections_${local.alert_suffix}"
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.evaluation_periods
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = local.alarm_period
  statistic           = "Average"
  threshold           = local.db_conn_alert_threshold
  alarm_description   = "Average database connections over ${local.db_conn_alert_threshold}, if database CPU alerts are getting raised as well. Please contact ${local.support_team}"
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  datapoints_to_alarm = local.datapoints_to_alarm

  dimensions = {
    DBInstanceIdentifier = local.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "db_connections_critical" {
  alarm_name          = "${local.application}_database_connections_${local.critical_suffix}"
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.evaluation_periods
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = local.alarm_period
  statistic           = "Average"
  threshold           = local.db_conn_critical_threshold
  alarm_description   = "Average database connections over ${local.db_conn_critical_threshold}, possible outage event. Please contact ${local.support_team}"
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  datapoints_to_alarm = local.datapoints_to_alarm

  dimensions = {
    DBInstanceIdentifier = local.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "swap_usage_critical" {
  alarm_name          = "${local.application}_database_swap-usage_${local.critical_suffix}"
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.evaluation_periods
  metric_name         = "SwapUsage"
  namespace           = "AWS/RDS"
  period              = local.alarm_period
  statistic           = "Average"
  threshold           = 20000
  alarm_description   = "Average database connections over 20000, possible outage event. Please contact ${local.support_team}"
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  datapoints_to_alarm = local.datapoints_to_alarm

  dimensions = {
    DBInstanceIdentifier = local.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "free_storage_space_warning" {
  alarm_name          = "${local.application}_database_free-storage-space_${local.warning_suffix}"
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = local.evaluation_periods
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = local.alarm_period
  statistic           = "Average"
  threshold           = local.database_storage_alert_threshold
  alarm_description   = "Database free storage space less than 10% of total storage space. Please contact ${local.support_team}"
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  datapoints_to_alarm = local.datapoints_to_alarm

  dimensions = {
    DBInstanceIdentifier = local.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "content_4xx_anomaly_detection" {
  alarm_name          = "${local.application}_content_tg_4xx-error-anomaly"
  alarm_description   = "Rate of 4xx errors is higher than expected. Please contact #ask_probation_webops on Slack"
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  comparison_operator = "GreaterThanUpperThreshold"
  threshold_metric_id = "ad1"
  evaluation_periods  = 1
  treat_missing_data  = "ignore"
  datapoints_to_alarm = local.datapoints_to_alarm

  metric_query {
    id          = "m1"
    return_data = "true"

    metric {
      metric_name = "HTTPCode_Target_4XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"

      dimensions = {
        LoadBalancer = data.terraform_remote_state.internal-load-balancer.outputs.info["arn_suffix"]
        TargetGroup  = data.terraform_remote_state.alfresco-content.outputs.info["tg_arn_suffix"]
      }
    }
  }

  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
    label       = "HTTPCode_Target_4XX_Count (expected)"
    return_data = "true"
  }
}
