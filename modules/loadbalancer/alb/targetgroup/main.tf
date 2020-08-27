resource "aws_lb_target_group" "environment" {
  name                 = "${var.appname}-tg"
  port                 = var.target_port
  protocol             = var.target_protocol
  vpc_id               = var.vpc_id
  deregistration_delay = var.deregistration_delay
  target_type          = var.target_type

  health_check {
    interval            = var.check_interval
    path                = var.check_path
    port                = var.check_port
    protocol            = var.check_protocol
    timeout             = var.timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    matcher             = var.return_code
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.appname}-tg"
    },
  )
}

