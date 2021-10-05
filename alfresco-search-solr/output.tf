output "info" {
  value = {
    loggroup_name          = module.create_loggroup.loggroup_name
    app_security_group     = aws_security_group.app.id
    access_security_group  = aws_security_group.access.id
    service_discovery_name = local.service_discovery_name
    end_point              = format("%s:%s", local.internal_private_dns_host, local.solr_port)
  }
}
