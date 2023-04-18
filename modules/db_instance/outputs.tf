locals {
  db_instance_address = element(
    concat(
      coalescelist(
        aws_db_instance.inst.*.address,
      ),
      [""],
    ),
    0,
  )
  db_instance_arn = element(
    concat(
      [""],
    ),
    0,
  )
  db_instance_availability_zone = element(
    concat(
      coalescelist(
        aws_db_instance.inst.*.availability_zone,
      ),
      [""],
    ),
    0,
  )
  db_instance_endpoint = element(
    concat(
      coalescelist(
        aws_db_instance.inst.*.endpoint,
      ),
      [""],
    ),
    0,
  )
  db_instance_hosted_zone_id = element(
    concat(
      coalescelist(
        aws_db_instance.inst.*.hosted_zone_id,
      ),
      [""],
    ),
    0,
  )
  db_instance_id = element(
    concat(
      coalescelist(
        aws_db_instance.inst.*.id,
      ),
      [""],
    ),
    0,
  )
  db_instance_resource_id = element(
    concat(
      coalescelist(
        aws_db_instance.inst.*.resource_id,
      ),
      [""],
    ),
    0,
  )
  db_instance_status = element(
    concat(
      coalescelist(
        aws_db_instance.inst.*.status,
      ),
      [""],
    ),
    0,
  )
  db_instance_name = element(
    concat(
      coalescelist(
        aws_db_instance.inst.*.name,
      ),
      [""],
    ),
    0,
  )
  db_instance_username = element(
    concat(
      coalescelist(
        aws_db_instance.inst.*.username,
      ),
      [""],
    ),
    0,
  )
  db_instance_password = element(
    concat(
      coalescelist(
        aws_db_instance.inst.*.password,
      ),
      [""],
    ),
    0,
  )
  db_instance_port = element(
    concat(
      coalescelist(
        aws_db_instance.inst.*.port,
      ),
      [""],
    ),
    0,
  )
  db_allocated_storage = element(
    concat(
      coalescelist(
        aws_db_instance.inst.*.allocated_storage,
      ),
      [""],
    ),
    0,
  )
  db_max_allocated_storage = element(
    concat(
      coalescelist(
        aws_db_instance.inst.*.max_allocated_storage,
      ),
      [""],
    ),
    0,
  )
}

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = local.db_instance_address
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = local.db_instance_arn
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = local.db_instance_availability_zone
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = local.db_instance_endpoint
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = local.db_instance_hosted_zone_id
}

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = local.db_instance_id
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of inst instance"
  value       = local.db_instance_resource_id
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = local.db_instance_status
}

output "db_instance_name" {
  description = "The database name"
  value       = local.db_instance_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = local.db_instance_username
}

output "db_instance_password" {
  description = "The database password (db password may be old, because Terraform doesn't track it after initial creation)"
  value       = local.db_instance_password
}

output "db_instance_port" {
  description = "The database port"
  value       = local.db_instance_port
}

output "db_instance_allocated_storage" {
  description = "The allocated storage in gibibytes (GiB)"
  value = local.db_allocated_storage
}

output "db_instance_max_allocated_storage" {
  description = "The upper limit to which Amazon RDS can automatically scale the storage of the DB instance"
  value = local.db_max_allocated_storage
}
