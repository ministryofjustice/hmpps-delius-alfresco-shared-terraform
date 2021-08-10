resource "aws_ssm_parameter" "config" {
  name        = format("%s/%s/running_config", local.alfresco_content_props["ssm_prefix"], local.application_name)
  description = "Runtime configuration for ECS container"
  type        = "SecureString"
  value = templatefile(
    "${path.module}/templates/config/runtime.conf",
    {}
  )
  tags = local.tags
}
