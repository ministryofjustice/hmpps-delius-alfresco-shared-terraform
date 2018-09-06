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
# SSH KEY
output "common_ssh_deployer_key" {
  value = "${module.ssh_key.deployer_key}"
}

## AWS PARAMETER STORE
output "common_ssm_ssh_private_key_name" {
  value = "${module.create_parameter_ssh_key_private.name}"
}
output "common_ssm_ssh_public_key_name" {
  value = "${module.create_parameter_ssh_key.name}"
}

# ENVIRONMENTS SETTINGS
# Route53
output "common_private_zone_id" {
  value = "${aws_route53_zone.internal_zone.zone_id}"
}

output "common_private_zone_name" {
  value = "${local.internal_domain}"
}

# tags
output "common_tags" {
  value = "${local.tags}"
}

