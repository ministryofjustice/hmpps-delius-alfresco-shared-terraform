resource "aws_lb_listener" "environment" {
  load_balancer_arn = var.lb_arn
  port              = var.lb_port
  protocol          = var.lb_protocol

  ssl_policy      = var.ssl_policy
  certificate_arn = element(var.certificate_arn, count.index)

  default_action {
    target_group_arn = var.target_group_arn
    type             = "forward"
  }
}

