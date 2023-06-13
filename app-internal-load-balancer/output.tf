output "info" {
  value = {
    security_group_id = aws_security_group.alb.id
    arn               = aws_lb.alb.arn
    arn_suffix        = aws_lb.alb.arn_suffix
    name              = aws_lb.alb.dns_name
    zone_id           = aws_lb.alb.zone_id
    dns_hostname      = local.dns_hostname
  }
}
