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

output "storage_s3bucket" {
  value = "${local.storage_s3bucket}"
}

# region
output "internal_domain" {
  value = "${local.internal_domain}"
}

# elk elb
output "elk_lb_dns" {
  value = "${local.elk_lb_dns}"
}

output "es_snapshot_name" {
  value = "${var.es_snapshot_name}"
}

# ASG
output "asg_prefix" {
  value = "${local.asg_prefix}"
}

# DynamoDB

output "dynamodb_table_name" {
  value = "${local.dynamodb_table_name}"
}

# restore status
output "alf_restore_status" {
  value = "${var.alf_restore_status}"
}

# rds
output "alf_db_host" {
  value = "${local.db_host}"
}

output "alf_db_name" {
  value = "${local.db_name}"
}

output "alf_db_username" {
  value = "${local.db_username}"
}

output "alf_db_password_ssm" {
  value = "${local.db_password_ssm}"
}

# env_configs
output "terragrunt_iam_role" {
  value = "${var.role_arn}"
}

output "region" {
  value = "${var.region}"
}
