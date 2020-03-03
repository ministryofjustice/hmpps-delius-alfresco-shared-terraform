# # ELB
output "alb_id" {
  description = "The name of the ELB"
  value       = "${aws_lb.environment.id}"
}

output "alb_name" {
  description = "The name of the ELB"
  value       = "${aws_lb.environment.dns_name}"
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the ELB (to be used in a Route 53 Alias record)"
  value       = "${aws_lb.environment.zone_id}"
}

output "alb_dns_cname" {
  value = "${aws_route53_record.dns_entry.fqdn}"
}
