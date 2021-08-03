#-------------------------------------------
### S3 bucket
#--------------------------------------------
module "bucket" {
  source         = "../modules/hmpps-terraform-modules/s3bucket/s3bucket_without_policy"
  s3_bucket_name = local.common_name
  tags           = local.tags
  versioning     = false
}

# -------------------------------------------
# ## Firehose 
# --------------------------------------------
resource "aws_kinesis_firehose_delivery_stream" "firehose" {
  depends_on = [aws_iam_role_policy.firehose_policy]

  name        = local.common_name
  destination = "elasticsearch"
  tags        = local.tags
  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = module.bucket.s3_bucket_arn
  }
  elasticsearch_configuration {
    domain_arn            = local.es_cluster_arn
    role_arn              = aws_iam_role.firehose_role.arn
    index_name            = local.alfresco_firehose_props["index_name"]
    type_name             = local.alfresco_firehose_props["index_name"]
    index_rotation_period = local.alfresco_firehose_props["index_rotation_period"]

    vpc_config {
      subnet_ids         = flatten(local.private_subnet_ids)
      security_group_ids = [aws_security_group.firehose.id]
      role_arn           = aws_iam_role.firehose_role.arn
    }
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = module.create_loggroup.loggroup_name
      log_stream_name = aws_cloudwatch_log_stream.firehose.name
    }
  }
  server_side_encryption {
    enabled  = true
    key_type = "AWS_OWNED_CMK"
  }
}
