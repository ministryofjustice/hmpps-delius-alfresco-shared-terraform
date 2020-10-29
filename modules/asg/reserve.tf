resource "aws_lb_target_group" "iwp" {
  name                 = "${local.common_prefix}-iwp"
  port                 = local.http_port
  protocol             = local.http_protocol
  vpc_id               = var.vpc_id
  deregistration_delay = 60
  target_type          = "instance"

  health_check {
    interval            = 30
    path                = "/alfresco/"
    port                = local.http_port
    protocol            = local.http_protocol
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-299"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 30
    enabled         = true
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.common_prefix}-iwp"
    },
  )
}

resource "aws_autoscaling_group" "iwp" {
  count                     = var.alf_deploy_iwp_fix
  name                      = "${local.common_prefix}-${aws_launch_configuration.environment.name}-iwp"
  vpc_zone_identifier       = flatten(local.subnet_ids)
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  launch_configuration      = aws_launch_configuration.environment.name
  health_check_grace_period = var.health_check_grace_period
  placement_group           = aws_placement_group.environment.id
  target_group_arns         = [aws_lb_target_group.iwp.arn]
  termination_policies      = var.termination_policies
  health_check_type         = var.health_check_type
  metrics_granularity       = var.metrics_granularity
  enabled_metrics           = var.enabled_metrics
  min_elb_capacity          = 1
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  default_cooldown          = var.default_cooldown

  lifecycle {
    create_before_destroy = true
  }
  tags = concat(
    [
      {
        key                 = "Name"
        value               = "${local.common_prefix}-${aws_launch_configuration.environment.name}-iwp"
        propagate_at_launch = true
      },
    ],
    data.null_data_source.tags.*.outputs
  )
}

resource "aws_lb_listener_rule" "iwp" {
  count        = var.alf_deploy_iwp_fix
  listener_arn = module.https_listener.listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.iwp.arn
  }

  condition {
    path_pattern {
      values = [
        "/alfresco/s/noms-spg/reserve/*",
        "/alfresco/aos/NOMS/*",
        "/alfresco/aos/_vti_bin"
      ]
    }
  }
}

