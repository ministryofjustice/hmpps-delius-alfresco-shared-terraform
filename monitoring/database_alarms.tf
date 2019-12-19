resource "aws_cloudwatch_metric_alarm" "db_cpu_critical" {
  alarm_name          = "${local.application}_database_cpu_${local.critical_suffix}"
  count               = "${local.messaging_status == "enabled" ? 1 : 0}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${local.evaluation_periods}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = "${local.cpu_critical_threshold}"
  alarm_description   = "Database CPU averaging over ${local.cpu_critical_threshold}, possible outage event. Please contact ${local.support_team}"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  dimensions {
    DBInstanceIdentifier = "${local.db_instance_id}"
  }
}

resource "aws_cloudwatch_metric_alarm" "db_cpu_alert" {
  alarm_name          = "${local.application}_database_cpu_${local.alert_suffix}"
  count               = "${local.messaging_status == "enabled" ? 1 : 0}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${local.evaluation_periods}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = "${local.cpu_alert_threshold}"
  alarm_description   = "Database CPU averaging over ${local.cpu_alert_threshold}, if database connection alerts are getting raised as well. Please contact ${local.support_team}"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  dimensions {
    DBInstanceIdentifier = "${local.db_instance_id}"
  }
}

resource "aws_cloudwatch_metric_alarm" "db_cpu_warning" {
  alarm_name          = "${local.application}_database_cpu_${local.warning_suffix}"
  count               = "${local.messaging_status == "enabled" ? 1 : 0}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${local.evaluation_periods}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = "${local.cpu_warning_threshold}"
  alarm_description   = "Database CPU averaging over ${local.cpu_warning_threshold}, check for database connection alerts."
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  dimensions {
    DBInstanceIdentifier = "${local.db_instance_id}"
  }
}

###

resource "aws_cloudwatch_metric_alarm" "db_connections_warning" {
  alarm_name          = "${local.application}_database_connections_${local.warning_suffix}"
  count               = "${local.messaging_status == "enabled" ? 1 : 0}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "${local.evaluation_periods}"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = "${local.db_conn_warning_threshold}"
  alarm_description   = "Average database connections over ${local.db_conn_warning_threshold}, check for database CPU alerts"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  dimensions {
    DBInstanceIdentifier = "${local.db_instance_id}"
  }
}

resource "aws_cloudwatch_metric_alarm" "db_connections_alert" {
  alarm_name          = "${local.application}_database_connections_${local.alert_suffix}"
  count               = "${local.messaging_status == "enabled" ? 1 : 0}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "${local.evaluation_periods}"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = "${local.db_conn_alert_threshold}"
  alarm_description   = "Average database connections over ${local.db_conn_alert_threshold}, if database CPU alerts are getting raised as well. Please contact ${local.support_team}"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  dimensions {
    DBInstanceIdentifier = "${local.db_instance_id}"
  }
}

resource "aws_cloudwatch_metric_alarm" "db_connections_critical" {
  alarm_name          = "${local.application}_database_connections_${local.critical_suffix}"
  count               = "${local.messaging_status == "enabled" ? 1 : 0}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "${local.evaluation_periods}"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = "${local.db_conn_critical_threshold}"
  alarm_description   = "Average database connections over ${local.db_conn_critical_threshold}, possible outage event. Please contact ${local.support_team}"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  dimensions {
    DBInstanceIdentifier = "${local.db_instance_id}"
  }
}

resource "aws_cloudwatch_metric_alarm" "swap_usage_critical" {
  alarm_name          = "${local.application}_database_swap-usage_${local.critical_suffix}"
  count               = "${local.messaging_status == "enabled" ? 1 : 0}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "${local.evaluation_periods}"
  metric_name         = "SwapUsage"
  namespace           = "AWS/RDS"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = 20000
  alarm_description   = "Average database connections over 20000, possible outage event. Please contact ${local.support_team}"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  dimensions {
    DBInstanceIdentifier = "${local.db_instance_id}"
  }
}

