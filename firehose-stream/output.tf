output "info" {
  value = {
    security_group_id = aws_security_group.firehose.id
    bucket_name       = module.bucket.s3_bucket_name
    # Commented out pending testing
    # stream_name       = aws_kinesis_firehose_delivery_stream.firehose.name
    stream_name = "dummy_kinesis_firehouse_delivery_stream_name"
    index_name  = local.alfresco_firehose_props["index_name"]
  }
}
