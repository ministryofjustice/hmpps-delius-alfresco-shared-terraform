# KMS Key
output "service_alfresco_rds_kms_arn" {
  value = "${module.kms_key.kms_arn}"
}

output "service_alfresco_rds_kms_id" {
  value = "${module.kms_key.kms_key_id}"
}

# IAM
output "service_alfresco_rds_monitoring_role_arn" {
  value = "${module.rds_monitoring_role.iamrole_arn}"
}

output "service_alfresco_rds_monitoring_role_name" {
  value = "${module.rds_monitoring_role.iamrole_name}"
}

# DB SUBNET GROUP
output "service_alfresco_rds_db_subnet_group_id" {
  value = "${module.db_subnet_group.db_subnet_group_id}"
}

output "service_alfresco_rds_db_subnet_group_arn" {
  value = "${module.db_subnet_group.db_subnet_group_arn}"
}

# PARAMETER GROUP
output "service_alfresco_rds_parameter_group_id" {
  value = "${module.db_parameter_group.db_parameter_group_id}"
}

output "service_alfresco_rds_parameter_group_arn" {
  value = "${module.db_parameter_group.db_parameter_group_arn}"
}

# DB OPTIONS GROUP
output "service_alfresco_rds_db_option_group_id" {
  value = "${module.db_option_group.db_option_group_id}"
}

output "service_alfresco_rds_db_option_group_arn" {
  value = "${module.db_option_group.db_option_group_arn}"
}

# DB INSTANCE
output "service_alfresco_rds_db_instance_address" {
  description = "The address of the RDS instance"
  value       = "${module.db_instance.db_instance_address}"
}

output "service_alfresco_rds_db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = "${module.db_instance.db_instance_arn}"
}

output "service_alfresco_rds_db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = "${module.db_instance.db_instance_availability_zone}"
}

output "service_alfresco_rds_db_instance_endpoint" {
  description = "The connection endpoint"
  value       = "${module.db_instance.db_instance_endpoint}"
}

output "service_alfresco_rds_db_instance_endpoint_cname" {
  description = "The connection endpoint"
  value       = "${local.dns_name}.${var.internal_domain}"
}

output "service_alfresco_rds_db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = "${module.db_instance.db_instance_hosted_zone_id}"
}

output "service_alfresco_rds_db_instance_id" {
  description = "The RDS instance ID"
  value       = "${module.db_instance.db_instance_id}"
}

output "service_alfresco_rds_db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = "${module.db_instance.db_instance_resource_id}"
}

output "service_alfresco_rds_db_instance_status" {
  description = "The RDS instance status"
  value       = "${module.db_instance.db_instance_status}"
}

output "service_alfresco_rds_db_instance_database_name" {
  description = "The database name"
  value       = "${module.db_instance.db_instance_name}"
}

output "service_alfresco_rds_db_instance_username" {
  description = "The master username for the database"
  value       = "${module.db_instance.db_instance_username}"
}

output "service_alfresco_rds_db_instance_port" {
  description = "The database port"
  value       = "${module.db_instance.db_instance_port}"
}
