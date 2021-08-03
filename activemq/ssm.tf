resource "random_password" "password" {
  length  = 25
  special = false
}

resource "random_password" "mq_admin_password" {
  length  = 25
  special = false
}

# Admin
resource "aws_ssm_parameter" "mq_master_username" {
  name        = format(var.alf_ssm_parameter_name_format, "mq", "admin_username")
  value       = local.mq_admin_user
  description = "MQ Username for the admin user"
  type        = "String"
  overwrite   = var.alf_overwrite_ssm_parameter
  tags        = local.tags
}

resource "aws_ssm_parameter" "mq_master_password" {
  name        = format(var.alf_ssm_parameter_name_format, "mq", "admin_password")
  value       = local.mq_admin_password
  description = "MQ Password for the admin user"
  type        = "SecureString"
  overwrite   = var.alf_overwrite_ssm_parameter
  tags        = local.tags
}

# User
resource "aws_ssm_parameter" "mq_application_username" {
  name        = format(var.alf_ssm_parameter_name_format, "mq", "application_username")
  value       = local.mq_application_user
  description = "AMQ username for the application user"
  type        = "String"
  overwrite   = var.alf_overwrite_ssm_parameter
}

resource "aws_ssm_parameter" "mq_application_password" {
  name        = format(var.alf_ssm_parameter_name_format, "mq", "application_password")
  value       = local.mq_application_password
  description = "AMQ password for the application user"
  type        = "SecureString"
  tags        = local.tags
}


