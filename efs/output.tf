# EFS content_store
output "content_store_efs_arn" {
  value = "${module.efs_content.efs_arn}"
}

output "content_store_efs_id" {
  value = "${module.efs_content.efs_id}"
}

output "content_store_efs_dns_name" {
  value = "${module.efs_content.efs_dns_name}"
}

output "content_store_dns_cname" {
  value = "${module.efs_content.dns_cname}"
}

# EFS content_store_deleted
output "content_store_deleted_efs_arn" {
  value = "${module.efs_content_deleted.efs_arn}"
}

output "content_store_deleted_efs_id" {
  value = "${module.efs_content_deleted.efs_id}"
}

output "content_store_deleted_efs_dns_name" {
  value = "${module.efs_content_deleted.efs_dns_name}"
}

output "content_store_deleted_dns_cname" {
  value = "${module.efs_content_deleted.dns_cname}"
}
