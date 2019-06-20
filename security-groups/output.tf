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

output "security_groups_sg_elasticache_sg_id" {
  value = "${module.security_groups.security_groups_sg_elasticache_sg_id}"
}

output "security_groups_sg_monitoring_client" {
  value = "${local.sg_map_ids["monitoring_client"]}"
}

output "security_groups_sg_efs_sg_id" {
  value = "${local.sg_map_ids["efs_sg_id"]}"
}

output "security_groups_bastion_in_sg_id" {
  value = "${local.sg_map_ids["bastion_in_sg_id"]}"
}

output "security_groups_map" {
  value = "${local.sg_map_ids}"
}
