resource "aws_cloudtrail" "environment" {
  name                          = "${var.cloudtrailname}-cloudtrail"
  s3_bucket_name                = var.s3_bucket_name
  include_global_service_events = var.globalevents
  is_multi_region_trail         = var.multiregion
  enable_logging                = var.enable_logging

  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type = "AWS::S3::Object"

      # Make sure to append a trailing '/' to your ARN if you want
      # to monitor all objects in a bucket.
      values = ["${var.s3_bucket_arn}/"]
    }
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.cloudtrailname}-cloudtrail"
    },
  )
}

