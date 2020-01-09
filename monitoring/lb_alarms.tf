locals {
  lb_error_req_threshold_critical = 60
  lb_error_req_threshold_alert    = 40
  lb_error_req_threshold_warning  = 20
}

resource "aws_cloudwatch_metric_alarm" "lb_4xx_error_request_critical" {
  alarm_name          = "${local.application}_loadbalancer_4xx-errors-requests_${local.critical_suffix}"
  count               = "${local.messaging_status == "enabled" ? 1 : 0}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${local.evaluation_periods}"
  threshold           = "${local.lb_error_req_threshold_critical}"
  alarm_description   = "LB Request 4XX error rate has exceeded ${local.lb_error_req_threshold_critical}%, check load balancer healthy instances"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  metric_query {
    id          = "e1"
    expression  = "m2/m1*100"
    label       = "Error Rate"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = "${local.alarm_period}"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        LoadBalancer = "${local.load_balancer_arn_suffix}"
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "HTTPCode_Target_4XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = "${local.alarm_period}"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        LoadBalancer = "${local.load_balancer_arn_suffix}"
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "lb_4xx_error_request_alert" {
  alarm_name          = "${local.application}_loadbalancer_4xx-errors-requests_${local.alert_suffix}"
  count               = "${local.messaging_status == "enabled" ? 1 : 0}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${local.evaluation_periods}"
  threshold           = "${local.lb_error_req_threshold_alert}"
  alarm_description   = "LB Request 4XX error rate has exceeded ${local.lb_error_req_threshold_alert}%, check load balancer healthy instances"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  metric_query {
    id          = "e1"
    expression  = "m2/m1*100"
    label       = "Error Rate"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = "${local.alarm_period}"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        LoadBalancer = "${local.load_balancer_arn_suffix}"
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "HTTPCode_Target_4XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = "${local.alarm_period}"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        LoadBalancer = "${local.load_balancer_arn_suffix}"
      }
    }
  }
}


resource "aws_cloudwatch_metric_alarm" "lb_4xx_error_request_warning" {
  alarm_name          = "${local.application}_loadbalancer_4xx-errors-requests_${local.warning_suffix}"
  count               = "${local.messaging_status == "enabled" ? 1 : 0}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${local.evaluation_periods}"
  threshold           = "${local.lb_error_req_threshold_warning}"
  alarm_description   = "LB Request 4XX error rate has exceeded ${local.lb_error_req_threshold_warning}%, check load balancer healthy instances"
  alarm_actions       = ["${aws_sns_topic.alarm_notification.arn}"]
  ok_actions          = ["${aws_sns_topic.alarm_notification.arn}"]

  metric_query {
    id          = "e1"
    expression  = "m2/m1*100"
    label       = "Error Rate"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = "${local.alarm_period}"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        LoadBalancer = "${local.load_balancer_arn_suffix}"
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "HTTPCode_Target_4XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = "${local.alarm_period}"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        LoadBalancer = "${local.load_balancer_arn_suffix}"
      }
    }
  }
}
