output "info" {
  value = {
    loggroup_name      = module.create_loggroup.loggroup_name
    app_secuirty_group = aws_security_group.app.id
  }
}


