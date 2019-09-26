output "common_account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

output "common_role_arn" {
  value = "${var.role_arn}"
}

output "common_sg_outbound_id" {
  value = "${aws_security_group.vpc-sg-outbound.id}"
}

# S3 Buckets
output "common_s3-config-bucket" {
  value = "${module.s3config_bucket.s3_bucket_name}"
}

output "common_s3_lb_logs_bucket" {
  value = "${module.s3_lb_logs_bucket.s3_bucket_name}"
}

# ENVIRONMENTS SETTINGS
# tags
output "common_tags" {
  value = "${local.tags}"
}
