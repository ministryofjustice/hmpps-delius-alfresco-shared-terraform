# target group
resource "aws_lb_target_group" "app" {
  name                 = substr(local.common_name, 0, 32)
  port                 = local.app_port
  protocol             = local.http_protocol
  vpc_id               = local.vpc_id
  deregistration_delay = 120
  target_type          = "ip"

  health_check {
    interval            = 30
    path                = local.alfresco_proxy_props["health_check_endpoint"]
    port                = local.app_port
    protocol            = local.http_protocol
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-299"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = tonumber(local.alfresco_proxy_props["cookie_duration"])
    enabled         = true
  }

  tags = merge(
    local.tags,
    {
      "Name" = local.common_name
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

# listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = local.lb_arn
  port              = local.app_port
  protocol          = local.http_protocol
  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      host        = "#{host}"
      port        = 443
      path        = "/#{path}"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }
}

# listener
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = local.lb_arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = local.alfresco_proxy_props["ssl_policy"]
  certificate_arn   = local.certificate_arn

  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      host        = "#{host}"
      port        = 443
      path        = "/share/page"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }
}

#Rules
resource "aws_lb_listener_rule" "app_rule" {
  listener_arn = aws_lb_listener.https_listener.arn

  condition {
    path_pattern {
      values = local.url_path_patterns
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
