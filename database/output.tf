# creds map
output "rds_creds" {
  value = {
    db_name               = local.db_name
    db_username_ssm_param = data.aws_ssm_parameter.db_user.name
    db_password_ssm_param = data.aws_ssm_parameter.db_password.name
  }
}

output "info" {
  value = {
    address               = try(module.database[0].db_instance_address, null)
    endpoint              = try(module.database[0].db_instance_endpoint, null)
    id                    = try(module.database[0].db_instance_id, null)
    allocated_storage     = try(module.database[0].db_instance_allocated_storage, null)
    max_allocated_storage = try(module.database[0].db_instance_max_allocated_storage, null)
    security_group_id     = data.terraform_remote_state.security-groups.outputs.security_groups_sg_rds_id
  }
}
