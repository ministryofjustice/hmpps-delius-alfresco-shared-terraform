resource "aws_s3_bucket_object" "s3_fluent_bit_conf" {
  bucket = local.config_bucket_name
  key    = local.fluentbit_s3_path
  content = templatefile(
    "../templates/config/fluentbit/fluent-bit.conf",
    {
      stream_name = local.firehose_stream_name
      region      = local.region
    }
  )
}
