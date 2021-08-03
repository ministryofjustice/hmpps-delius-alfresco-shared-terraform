resource "aws_mq_broker" "broker" {
  broker_name         = local.identifier
  engine_type         = local.alfresco_activemq_props["engine_type"]
  engine_version      = local.alfresco_activemq_props["engine_version"]
  deployment_mode     = local.alfresco_activemq_props["deployment_mode"]
  host_instance_type  = local.alfresco_activemq_props["host_instance_type"]
  publicly_accessible = false
  security_groups     = [aws_security_group.activemq.id]
  tags                = local.tags
  subnet_ids = [
    local.subnet_ids[0],
    local.subnet_ids[1]
  ]
  encryption_options {
    kms_key_id        = var.kms_mq_key_arn
    use_aws_owned_key = var.use_aws_owned_key
  }

  user {
    username       = local.mq_admin_user
    password       = local.mq_admin_password
    groups         = ["admin"]
    console_access = false
  }

  user {
    username = local.mq_application_user
    password = local.mq_application_password
  }

  auto_minor_version_upgrade = false

  logs {
    general = true
    audit   = true
  }

  maintenance_window_start_time {
    day_of_week = local.alfresco_activemq_props["day_of_week"]
    time_of_day = local.alfresco_activemq_props["time_of_day"]
    time_zone   = local.alfresco_activemq_props["time_zone"]
  }
}
