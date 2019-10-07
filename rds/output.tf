####################################################
# RDS - Application specific
####################################################
# KMS Key
output "rds_kms_arn" {
  value = "${module.rds.rds_kms_arn}"
}

output "rds_kms_id" {
  value = "${module.rds.rds_kms_id}"
}

# IAM
output "rds_monitoring_role_arn" {
  value = "${module.rds.rds_monitoring_role_arn}"
}

output "rds_monitoring_role_name" {
  value = "${module.rds.rds_monitoring_role_name}"
}

# DB SUBNET GROUP
output "rds_db_subnet_group_id" {
  value = "${module.rds.rds_db_subnet_group_id}"
}

output "rds_db_subnet_group_arn" {
  value = "${module.rds.rds_db_subnet_group_arn}"
}

# PARAMETER GROUP
output "rds_parameter_group_id" {
  value = "${module.rds.rds_parameter_group_id}"
}

output "rds_parameter_group_arn" {
  value = "${module.rds.rds_parameter_group_arn}"
}

# DB OPTIONS GROUP
output "rds_db_option_group_id" {
  value = "${module.rds.rds_db_option_group_id}"
}

output "rds_db_option_group_arn" {
  value = "${module.rds.rds_db_option_group_arn}"
}

# DB INSTANCE
output "rds_db_instance_address" {
  description = "The address of the RDS instance"
  value       = "${module.rds.rds_db_instance_address}"
}

output "rds_db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = "${module.rds.rds_db_instance_arn}"
}

output "rds_db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = "${module.rds.rds_db_instance_availability_zone}"
}

output "rds_db_instance_endpoint" {
  description = "The connection endpoint"
  value       = "${module.rds.rds_db_instance_endpoint}"
}

output "rds_db_instance_endpoint_cname" {
  description = "The connection endpoint"
  value       = "${module.rds.rds_db_instance_endpoint_cname}"
}

output "rds_db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = "${module.rds.rds_db_instance_hosted_zone_id}"
}

output "rds_db_instance_id" {
  description = "The RDS instance ID"
  value       = "${module.rds.rds_db_instance_id}"
}

output "rds_db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = "${module.rds.rds_db_instance_resource_id}"
}

output "rds_db_instance_status" {
  description = "The RDS instance status"
  value       = "${module.rds.rds_db_instance_status}"
}

output "rds_db_instance_database_name" {
  description = "The database name"
  value       = "${module.rds.rds_db_instance_database_name}"
}

output "rds_db_instance_username" {
  description = "The master username for the database"
  value       = "${module.rds.rds_db_instance_username}"
}

output "rds_db_instance_port" {
  description = "The database port"
  value       = "${module.rds.rds_db_instance_port}"
}

# creds
output "rds_creds" {
  value = "${module.rds.rds_creds}"
}

# logs
output "log_groups" {
  value = "${module.rds.log_groups}"
}

output "aws_logs_prefix" {
  value = "${module.rds.aws_logs_prefix}"
}
