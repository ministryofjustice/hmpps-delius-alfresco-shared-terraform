resource "aws_ssm_parameter" "config" {
  name        = format("%s/%s/running_config", local.alfresco_content_props["ssm_prefix"], local.application_name)
  description = "Runtime configuration for ECS container"
  type        = "SecureString"
  value = templatefile(
    "${path.module}/templates/config/runtime.conf",
    {
      db_name          = data.terraform_remote_state.rds.outputs.rds_creds["db_name"]
      db_user          = data.aws_ssm_parameter.db_user.value
      db_password      = data.aws_ssm_parameter.db_password.value
      db_endpoint      = "alfresco-database2.cbtjc5uz9xwp.eu-west-2.rds.amazonaws.com:5432" #data.terraform_remote_state.rds.outputs.info["address"]
      heap_size        = tonumber(local.alfresco_content_props["heap_size"])
      solr_host        = "solr6"
      solr_port        = 8983
      share_host       = "127.0.0.1"
      share_port       = 8080
      alfresco_host    = "localhost"
      alfresco_port    = 8080
      s3_bucket_name   = aws_s3_bucket.s3.id #local.storage_bucket_name
      s3_bucket_region = local.region
    }
  )
  tags = local.tags
}
