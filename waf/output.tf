output "waf_data" {
  value = {
    firehose_stream_arn    = aws_kinesis_firehose_delivery_stream.firehose_stream.arn
    firehose_stream_name   = local.firehose_stream_name
    firehose_stream_bucket = aws_s3_bucket.firehose.id
    waf_id                 = aws_wafregional_web_acl.wafacl.id
    waf_acl                = local.web_acl_name
  }
}

