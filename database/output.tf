# DB INSTANCE
output "rds_db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.db_instance.db_instance_address
}

output "rds_db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.db_instance.db_instance_arn
}

output "rds_db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = module.db_instance.db_instance_availability_zone
}

output "rds_db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.db_instance.db_instance_endpoint
}

output "rds_db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = module.db_instance.db_instance_hosted_zone_id
}

output "rds_db_instance_id" {
  description = "The RDS instance ID"
  value       = module.db_instance.db_instance_id
}

output "rds_db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = module.db_instance.db_instance_resource_id
}

output "rds_db_instance_status" {
  description = "The RDS instance status"
  value       = module.db_instance.db_instance_status
}

output "rds_db_instance_database_name" {
  description = "The database name"
  value       = module.db_instance.db_instance_name
}

output "rds_db_instance_username" {
  description = "The master username for the database"
  value       = module.db_instance.db_instance_username
}

output "rds_db_instance_port" {
  description = "The database port"
  value       = module.db_instance.db_instance_port
}

output "rds_db_instance_endpoint_cname" {
  description = "The connection endpoint"
  value       = aws_route53_record.rds_dns_entry.fqdn
}

# creds map
output "rds_creds" {
  value = {
    db_name               = local.db_name
    db_username_ssm_param = data.aws_ssm_parameter.db_user.name
    db_password_ssm_param = data.aws_ssm_parameter.db_password.name
  }
}

output "aurora" {
  value = {
    cluster_endpoint = module.db.this_rds_cluster_endpoint
    reader_endpoint  = module.db.this_rds_cluster_endpoint
  }
}
