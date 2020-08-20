output "listener_id" {
  value = aws_lb_listener.environment.*.id
}

output "listener_arn" {
  value = aws_lb_listener.environment.*.arn
}

