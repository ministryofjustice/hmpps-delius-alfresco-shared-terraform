# EFS backups
output "efs_arn" {
  value = "${module.efs_backups.efs_arn}"
}

output "efs_id" {
  value = "${module.efs_backups.efs_id}"
}

output "efs_dns_name" {
  value = "${module.efs_backups.efs_dns_name}"
}

output "dns_cname" {
  value = "${module.efs_backups.dns_cname}"
}
