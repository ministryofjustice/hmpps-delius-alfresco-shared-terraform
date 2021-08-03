resource "aws_ssm_parameter" "config" {
  name        = format("%s/%s/running_config", local.alfresco_share_props["ssm_prefix"], local.application_name)
  description = "Runtime configuration for ECS container"
  type        = "SecureString"
  value = templatefile(
    "${path.module}/templates/config/java_opts.conf",
    {
      alfresco_host = local.internal_private_dns_host
      alfresco_port = 8080
    }
  )
  tags = local.tags
}
