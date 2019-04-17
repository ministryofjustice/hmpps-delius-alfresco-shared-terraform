# EFS backups
output "backups_efs_arn" {
  value = "${module.efs_backups.efs_arn}"
}

output "backups_efs_id" {
  value = "${module.efs_backups.efs_id}"
}

output "backups_efs_dns_name" {
  value = "${module.efs_backups.efs_dns_name}"
}
