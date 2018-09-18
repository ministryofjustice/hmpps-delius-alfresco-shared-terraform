####################################################
# SECURITY GROUPS - Application specific
####################################################
output "security_groups_sg_internal_lb_id" {
  value = "${module.security_groups.security_groups_sg_internal_lb_id}"
}

output "security_groups_sg_internal_instance_id" {
  value = "${module.security_groups.security_groups_sg_internal_instance_id}"
}

output "security_groups_sg_rds_id" {
  value = "${module.security_groups.security_groups_sg_rds_id}"
}

output "security_groups_sg_external_lb_id" {
  value = "${module.security_groups.security_groups_sg_external_lb_id}"
}

output "security_groups_sg_external_instance_id" {
  value = "${module.security_groups.security_groups_sg_external_instance_id}"
}
