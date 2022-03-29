resource "aws_ssm_parameter" "config" {
  name        = format("%s/%s/running_config", local.alfresco_content_props["ssm_prefix"], local.application_name)
  description = "Runtime configuration for ECS container"
  type        = "SecureString"
  value = templatefile(
    "${path.module}/templates/config/runtime.conf",
    {
      db_name                          = data.terraform_remote_state.rds.outputs.rds_creds["db_name"]
      db_user                          = data.aws_ssm_parameter.db_user.value
      db_password                      = data.aws_ssm_parameter.db_password.value
      db_endpoint                      = data.terraform_remote_state.rds.outputs.info["address"]
      memory                           = tonumber(local.alfresco_content_props["memory"])
      solr_host                        = local.internal_private_dns_host
      solr_port                        = local.solr_port
      share_host                       = local.internal_private_dns_host
      share_port                       = 8070
      alfresco_host                    = format("https://%s", local.external_private_dns_host)
      base_url_overwrite               = format("https://%s", local.external_private_dns_host)
      alfresco_port                    = 443
      alfresco_protocol                = "https"
      transform_host                   = local.internal_private_dns_host
      transform_port                   = 8090
      s3_bucket_name                   = local.storage_bucket_name
      s3_bucket_region                 = local.region
      cache_location                   = local.cache_location
      server_allowWrite                = true
      db_schema_update                 = true
      download_cleaner_repeat_delay_ms = 315569520000 # Set for a long time to effectively disable
      download_cleaner_start_delay_ms  = 315569520000 # Set for a long time to effectively disable
    }
  )
  tags = local.tags
}
