output "info" {
  value = {
    loggroup_name      = module.create_loggroup.loggroup_name
    app_security_group = aws_security_group.app.id
  }
}


