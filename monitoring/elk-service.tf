resource "aws_cloudwatch_metric_alarm" "es_cluster_critical" {
  alarm_name          = "${local.application}_elasticsearch_cluster_red_state_${local.critical_suffix}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.evaluation_periods
  metric_name         = "ClusterStatus.red"
  namespace           = "AWS/ES"
  period              = local.short_alarm_period
  statistic           = "Maximum"
  threshold           = "1"
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  alarm_description   = "ElasticSearch cluster in red state, possible data loss. Please contact ${local.support_team}"
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  datapoints_to_alarm = local.datapoints_to_alarm

  dimensions = {
    DomainName = local.elasticsearch_domain
    ClientId   = local.account_id
  }
}

resource "aws_cloudwatch_metric_alarm" "es_cluster_warning" {
  alarm_name          = "${local.application}_elasticsearch_cluster_yellow_state_${local.warning_suffix}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.evaluation_periods
  metric_name         = "ClusterStatus.yellow"
  namespace           = "AWS/ES"
  period              = local.short_alarm_period
  statistic           = "Maximum"
  threshold           = "1"
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  alarm_description   = "ElasticSearch cluster in red state, possible data loss. Please contact ${local.support_team}"
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  datapoints_to_alarm = local.datapoints_to_alarm

  dimensions = {
    DomainName = local.elasticsearch_domain
    ClientId   = local.account_id
  }
}

resource "aws_cloudwatch_metric_alarm" "es_snapshot_warning" {
  alarm_name          = "${local.application}_elasticsearch_automated_snapshot_${local.warning_suffix}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.evaluation_periods
  metric_name         = "AutomatedSnapshotFailure"
  namespace           = "AWS/ES"
  period              = local.alarm_period
  statistic           = "Maximum"
  threshold           = "1"
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  alarm_description   = "ElasticSearch automated snapshot failure, possible data loss. Please contact ${local.support_team}"
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  datapoints_to_alarm = local.datapoints_to_alarm

  dimensions = {
    DomainName = local.elasticsearch_domain
    ClientId   = local.account_id
  }
}
