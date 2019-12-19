resource "aws_cloudwatch_metric_alarm" "lb_unhealthy_critical" {
  alarm_name          = "${local.application}_loadbalancer_unhealthy-hosts_${local.critical_suffix}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  count               = "${local.messaging_status == "enabled" ? 1 : 0}"
  evaluation_periods  = "${local.evaluation_periods}"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ELB"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = "${local.inst_critical_threshold}"
  alarm_description   = "All hosts are unhealthy, possible outage event. Please contact ${local.support_team}"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  dimensions {
    LoadBalancerName = "${local.load_balancer_name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "lb_unhealthy_alert" {
  alarm_name          = "${local.application}_loadbalancer_unhealthy-hosts_${local.alert_suffix}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  count               = "${local.inst_alert_threshold > 1 ? 1 : 0}"
  evaluation_periods  = "${local.evaluation_periods}"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ELB"
  period              = "${local.alarm_period}"
  statistic           = "Average"
  threshold           = "${local.inst_alert_threshold}"
  alarm_description   = "${local.inst_alert_threshold} hosts are unhealthy, check for EC2 instances maybe an instance is cycling. Please contact ${local.support_team}"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  dimensions {
    LoadBalancerName = "${local.load_balancer_name}"
  }
}
