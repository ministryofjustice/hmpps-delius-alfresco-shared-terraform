# SECURITY GROUPS

output "security_groups_sg_internal_lb_id" {
  value = "${local.internal_lb_sg_id}"
}

output "security_groups_sg_internal_instance_id" {
  value = "${local.internal_inst_sg_id}"
}

output "security_groups_sg_rds_id" {
  value = "${local.db_sg_id}"
}

output "security_groups_sg_external_lb_id" {
  value = "${local.external_lb_sg_id}"
}

output "security_groups_sg_external_instance_id" {
  value = "${local.external_inst_sg_id}"
}

output "security_groups_sg_elasticache_sg_id" {
  value = "${local.elasticache_sg_id}"
}
