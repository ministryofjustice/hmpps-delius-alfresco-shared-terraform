output "info" {
  value = {
    loggroup_name         = module.create_loggroup.loggroup_name
    app_secuirty_group    = aws_security_group.app.id
    access_security_group = aws_security_group.access.id
    end_point             = format("%s:%s", local.internal_private_dns_host, local.app_port)
    storage_bucket_name   = local.storage_bucket_name
  }
}


