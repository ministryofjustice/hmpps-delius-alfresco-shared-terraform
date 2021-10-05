# target group
resource "aws_lb_target_group" "app" {
  name                 = local.common_name
  port                 = local.target_group_port
  protocol             = local.http_protocol
  vpc_id               = local.vpc_id
  deregistration_delay = 120
  target_type          = "ip"

  health_check {
    interval            = 30
    path                = "/share/page/"
    port                = local.app_port
    protocol            = local.http_protocol
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-299"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = tonumber(local.alfresco_share_props["cookie_duration"])
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
  port              = local.target_group_port
  protocol          = local.http_protocol
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Please use specific URL path"
      status_code  = "200"
    }
  }
}

#Rules
resource "aws_lb_listener_rule" "app_rule" {
  listener_arn = aws_lb_listener.http_listener.arn

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
