# EFS backups
output "info" {
  value = {
    security_group_id  = aws_security_group.activemq.id
    broker_id          = aws_mq_broker.broker.id
    broker_arn         = aws_mq_broker.broker.arn
    primary_endpoint   = try(aws_mq_broker.broker.instances[0].endpoints[0], "")
    secondary_endpoint = try(aws_mq_broker.broker.instances[1].endpoints[0], "")
  }
}

output "ssm_info" {
  value = {
    admin_user           = aws_ssm_parameter.mq_master_username.name
    admin_password       = aws_ssm_parameter.mq_master_password.name
    application_user     = aws_ssm_parameter.mq_application_username.name
    application_password = aws_ssm_parameter.mq_application_password.name
  }
}
