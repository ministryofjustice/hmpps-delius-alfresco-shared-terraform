output "info" {
  value = {
    security_group_id = aws_security_group.firehose.id
    bucket_name       = module.bucket.s3_bucket_name
    stream_name       = aws_kinesis_firehose_delivery_stream.firehose.name
    index_name        = local.alfresco_firehose_props["index_name"]
  }
}
