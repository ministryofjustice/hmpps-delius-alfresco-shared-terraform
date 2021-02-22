resource "aws_cloudwatch_metric_alarm" "solr_lb_unhealthy_critical" {
  alarm_name          = "${local.application}_solr_loadbalancer_healthy-hosts_${local.critical_suffix}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = local.evaluation_periods
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = local.alarm_period
  statistic           = "Average"
  threshold           = "1"
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  alarm_description   = "All SOLR hosts are unhealthy, possible outage event. Please contact ${local.support_team}"
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  datapoints_to_alarm = local.datapoints_to_alarm

  dimensions = {
    LoadBalancer = local.solr_load_balancer_arn_suffix
    TargetGroup  = local.solr_target_group_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "solr_lb_unhealthy_alert" {
  alarm_name          = "${local.application}_solr_loadbalancer_healthy-hosts_${local.alert_suffix}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = local.evaluation_periods
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = local.alarm_period
  statistic           = "Average"
  threshold           = "2"
  count               = 0
  actions_enabled     = local.messaging_status == "enabled" ? true : false
  alarm_description   = "Some Solr hosts are unhealthy, check for EC2 instances maybe an instance is cycling. Please contact ${local.support_team}"
  alarm_actions       = [aws_sns_topic.alarm_notification.arn]
  ok_actions          = [aws_sns_topic.alarm_notification.arn]
  datapoints_to_alarm = local.datapoints_to_alarm

  dimensions = {
    LoadBalancer = local.solr_load_balancer_arn_suffix
    TargetGroup  = local.solr_target_group_suffix
  }
}
