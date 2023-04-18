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
    address               = module.database.db_instance_address
    endpoint              = module.database.db_instance_endpoint
    id                    = module.database.db_instance_id
    allocated_storage     = module.database.db_instance_allocated_storage
    max_allocated_storage = module.database.db_instance_max_allocated_storage
    security_group_id     = data.terraform_remote_state.security-groups.outputs.security_groups_sg_rds_id
  }
}
