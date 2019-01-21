# EFS
output "efs_arn" {
  value = "${aws_efs_file_system.efs.arn}"
}

output "efs_id" {
  value = "${aws_efs_file_system.efs.id}"
}

output "efs_dns_name" {
  value = "${aws_efs_file_system.efs.dns_name}"
}

# Route53
output "dns_cname" {
  value = "${local.dns_host}"
}
