resource "aws_cloudwatch_metric_alarm" "solr_lb_unhealthy_critical" {
  alarm_name          = "${local.application}_solr_loadbalancer_healthy-hosts_${local.critical_suffix}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "${local.evaluation_periods}"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = "1"
  actions_enabled     = "${local.messaging_status == "enabled" ? 1 : 0}"
  alarm_description   = "All SOLR hosts are unhealthy, possible outage event. Please contact ${local.support_team}"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]
  datapoints_to_alarm = "${local.datapoints_to_alarm}"

  dimensions {
    LoadBalancer = "${local.solr_load_balancer_arn_suffix}"
    TargetGroup  = "${local.solr_target_group_suffix}"
  }
}

