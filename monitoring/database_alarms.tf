resource "aws_cloudwatch_metric_alarm" "cpu_utilization_too_high" {
  alarm_name          = "alf_db_cpu_utilization_too_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = 60
  alarm_description   = "Average database CPU utilization over last ${local.alarm_period / 60} minutes too high"
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

resource "aws_cloudwatch_metric_alarm" "database_connections_too_high" {
  alarm_name          = "alf_db_connections_too_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = 300
  alarm_description   = "Average database connections over last ${local.alarm_period / 60} minutes too high, performance may suffer"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  dimensions {
    DBInstanceIdentifier = "${local.db_instance_id}"
  }
}

resource "aws_cloudwatch_metric_alarm" "swap_usage_too_high" {
  alarm_name          = "alf_db_swap_usage_too_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SwapUsage"
  namespace           = "AWS/RDS"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = 20000
  alarm_description   = "Average database swap usage over last ${local.alarm_period / 60} minutes too high, performance may suffer"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  dimensions {
    DBInstanceIdentifier = "${local.db_instance_id}"
  }
}

