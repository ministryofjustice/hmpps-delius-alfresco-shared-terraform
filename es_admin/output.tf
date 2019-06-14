# ec2

output "es_admin_host" {
  value = "${aws_route53_record.instance.fqdn}"
}

# s3bucket
output "elk_bucket_name" {
  value = "${local.elk_bucket_name}"
}

output "config_bucket" {
  value = "${local.config-bucket}"
}

# region
output "internal_domain" {
  value = "${local.internal_domain}"
}

# elk elb
output "elk_lb_dns" {
  value = "${local.elk_lb_dns}"
}
