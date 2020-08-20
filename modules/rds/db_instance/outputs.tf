locals {
  db_instance_address           = "${element(concat(coalescelist(aws_db_instance.inst_mssql.*.address, aws_db_instance.inst.*.address), list("")), 0)}"
  db_instance_arn               = "${element(concat(coalescelist(aws_db_instance.inst_mssql.*.arn, aws_db_instance.inst.*.arn), list("")), 0)}"
  db_instance_availability_zone = "${element(concat(coalescelist(aws_db_instance.inst_mssql.*.availability_zone, aws_db_instance.inst.*.availability_zone), list("")), 0)}"
  db_instance_endpoint          = "${element(concat(coalescelist(aws_db_instance.inst_mssql.*.endpoint, aws_db_instance.inst.*.endpoint), list("")), 0)}"
  db_instance_hosted_zone_id    = "${element(concat(coalescelist(aws_db_instance.inst_mssql.*.hosted_zone_id, aws_db_instance.inst.*.hosted_zone_id), list("")), 0)}"
  db_instance_id                = "${element(concat(coalescelist(aws_db_instance.inst_mssql.*.id, aws_db_instance.inst.*.id), list("")), 0)}"
  db_instance_resource_id       = "${element(concat(coalescelist(aws_db_instance.inst_mssql.*.resource_id, aws_db_instance.inst.*.resource_id), list("")), 0)}"
  db_instance_status            = "${element(concat(coalescelist(aws_db_instance.inst_mssql.*.status, aws_db_instance.inst.*.status), list("")), 0)}"
  db_instance_name              = "${element(concat(coalescelist(aws_db_instance.inst_mssql.*.name, aws_db_instance.inst.*.name), list("")), 0)}"
  db_instance_username          = "${element(concat(coalescelist(aws_db_instance.inst_mssql.*.username, aws_db_instance.inst.*.username), list("")), 0)}"
  db_instance_password          = "${element(concat(coalescelist(aws_db_instance.inst_mssql.*.password, aws_db_instance.inst.*.password), list("")), 0)}"
  db_instance_port              = "${element(concat(coalescelist(aws_db_instance.inst_mssql.*.port, aws_db_instance.inst.*.port), list("")), 0)}"
}

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = "${local.db_instance_address}"
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = "${local.db_instance_arn}"
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = "${local.db_instance_availability_zone}"
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = "${local.db_instance_endpoint}"
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = "${local.db_instance_hosted_zone_id}"
}

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = "${local.db_instance_id}"
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of inst instance"
  value       = "${local.db_instance_resource_id}"
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = "${local.db_instance_status}"
}

output "db_instance_name" {
  description = "The database name"
  value       = "${local.db_instance_name}"
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = "${local.db_instance_username}"
}

output "db_instance_password" {
  description = "The database password (db password may be old, because Terraform doesn't track it after initial creation)"
  value       = "${local.db_instance_password}"
}

output "db_instance_port" {
  description = "The database port"
  value       = "${local.db_instance_port}"
}
