#-------------------------------------------
### S3 bucket for elk backups
#--------------------------------------------

resource "aws_s3_bucket" "elk_backups" {
  bucket = "${local.common_name}-elk-mig"
  acl    = "private"

  versioning {
    enabled = false
  }

  lifecycle {
    prevent_destroy = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${module.s3bucket.s3bucket_kms_id}"
        sse_algorithm     = "aws:kms"
      }
    }
  }
  lifecycle_rule {
    enabled = true
    expiration {
      days = 2
    }
  }

  tags = "${merge(local.tags, map("Name", "${local.common_name}-s3-bucket"))}"
}

resource "aws_s3_bucket_metric" "elk_backups" {
  bucket = "${aws_s3_bucket.elk_backups.bucket}"
  name   = "EntireBucket"
}
