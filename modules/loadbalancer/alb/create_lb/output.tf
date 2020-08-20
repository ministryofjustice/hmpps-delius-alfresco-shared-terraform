output "lb_id" {
  value = aws_lb.environment.id
}

output "lb_arn" {
  value = aws_lb.environment.arn
}

output "lb_arn_suffix" {
  value = aws_lb.environment.arn_suffix
}

output "lb_dns_name" {
  value = aws_lb.environment.dns_name
}

# output "lb_canonical_hosted_zone_id" {
#   value = "${aws_lb.environment.canonical_hosted_zone_id}"
# }

output "lb_zone_id" {
  value = aws_lb.environment.zone_id
}

