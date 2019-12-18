locals {
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
}


resource "aws_cloudwatch_metric_alarm" "db_cpu_critical" {
  alarm_name          = "${local.application}_database_cpu_${local.critical_suffix}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
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
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
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
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
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


resource "aws_cloudwatch_metric_alarm" "disk_queue_depth_too_high" {
  alarm_name          = "alf_db_disk_queue_depth_too_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DiskQueueDepth"
  namespace           = "AWS/RDS"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "Average database disk queue depth over last ${local.alarm_period / 60} minutes too high, performance may suffer"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  dimensions {
    DBInstanceIdentifier = "${local.db_instance_id}"
  }
}


###

resource "aws_cloudwatch_metric_alarm" "db_connections_warning" {
  alarm_name          = "${local.application}_database_connections_${local.warning_suffix}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
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
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
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
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
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
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
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

