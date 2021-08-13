output "info" {
  value = {
    security_group_id = aws_security_group.alb.id
    id                = aws_lb.alb.id
    name              = aws_lb.alb.dns_name
    zone_id           = aws_lb.alb.zone_id
    dns_hostname      = local.dns_hostname
  }
}
