#-------------------------------------------
### S3 bucket for backups
#--------------------------------------------

resource "aws_s3_bucket" "firehose" {
  bucket = "${local.common_name}-firehose"
  acl    = "private"

  versioning {
    enabled = false
  }

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    enabled = true
    transition {
      days          = "90"
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = "180"
      storage_class = "GLACIER"
    }

    expiration {
      days = "730"
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.common_name}-firehose"
    },
  )
}

resource "aws_s3_bucket_metric" "firehouse" {
  bucket = aws_s3_bucket.firehose.bucket
  name   = "EntireBucket"
}

