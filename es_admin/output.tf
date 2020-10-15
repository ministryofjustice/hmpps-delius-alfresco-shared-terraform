# ec2

output "es_admin_host" {
  value = aws_route53_record.instance.fqdn
}

output "private_ip" {
  value = aws_instance.instance.private_ip
}

# s3bucket
output "elk_bucket_name" {
  value = local.elk_bucket_name
}

output "config_bucket" {
  value = local.config-bucket
}

output "storage_s3bucket" {
  value = local.storage_s3bucket
}

output "backups_bucket" {
  value = local.backups_bucket
}

# region
output "internal_domain" {
  value = local.internal_domain
}

output "es_snapshot_name" {
  value = var.es_snapshot_name
}

output "elk_s3_repo_name" {
  value = var.es_s3_repo_name
}

# ASG
output "asg_prefix" {
  value = local.asg_prefix
}

# restore status
output "alf_restore_status" {
  value = var.alf_restore_status
}

# rds
output "alf_db_host" {
  value = local.db_host
}

output "alf_db_name" {
  value = local.db_name
}

output "alf_db_username_ssm" {
  value = local.db_username_ssm
}

output "alf_db_password_ssm" {
  value = local.db_password_ssm
}

# env_configs
output "terragrunt_iam_role" {
  value = var.role_arn
}

output "region" {
  value = var.region
}

output "loggroup_name" {
  value = module.create_loggroup.loggroup_name
}

