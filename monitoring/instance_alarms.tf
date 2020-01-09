resource "aws_cloudwatch_metric_alarm" "lb_unhealthy_critical" {
  alarm_name          = "${local.application}_loadbalancer_healthy-hosts_${local.critical_suffix}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "${local.evaluation_periods}"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = "1"
  actions_enabled     = "${local.messaging_status == "enabled" ? 1 : 0}"
  alarm_description   = "All hosts are unhealthy, possible outage event. Please contact ${local.support_team}"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]
  datapoints_to_alarm = "${local.datapoints_to_alarm}"

  dimensions {
    LoadBalancer = "${local.load_balancer_arn_suffix}"
    TargetGroup  = "${local.target_group_suffix}"
  }
}


resource "aws_cloudwatch_metric_alarm" "lb_unhealthy_alert" {
  alarm_name          = "${local.application}_loadbalancer_healthy-hosts_${local.alert_suffix}"
  comparison_operator = "LessThanThreshold"
  count               = "${local.inst_alert_threshold >= 2 ? 1 : 0}"
  evaluation_periods  = "${local.evaluation_periods}"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  actions_enabled     = "${local.messaging_status == "enabled" ? 1 : 0}"
  threshold           = "${local.inst_alert_threshold}"
  alarm_description   = "${local.inst_alert_threshold} hosts are unhealthy, check for EC2 instances maybe an instance is cycling. Please contact ${local.support_team}"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]
  datapoints_to_alarm = "${local.datapoints_to_alarm}"

  dimensions {
    LoadBalancer = "${local.load_balancer_arn_suffix}"
    TargetGroup  = "${local.target_group_suffix}"
  }
}
