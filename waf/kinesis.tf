resource "aws_iam_role" "firehose_role" {
  name = "${local.common_name}-firehose-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name = "${local.firehose_stream_name}"
  destination = "s3"

  s3_configuration {
    role_arn = "${aws_iam_role.firehose_role.arn}"
    bucket_arn = "${aws_s3_bucket.firehose.arn}"
    buffer_size = 5
    buffer_interval = 300
    compression_format = "GZIP"
    prefix = "/incoming"
    cloudwatch_logging_options {
      enabled = true
      log_group_name = "${local.common_name}-firehose"
      log_stream_name = "delivery"
    }
  }
}
