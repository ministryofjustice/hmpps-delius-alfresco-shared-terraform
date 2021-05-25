resource "aws_lb_listener" "environment" {
  load_balancer_arn = var.lb_arn
  port              = var.lb_port
  protocol          = var.lb_protocol
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "401"
      message_body = var.message_body
    }
  }
}

