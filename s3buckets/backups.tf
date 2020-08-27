#-------------------------------------------
### S3 bucket for backups
#--------------------------------------------

resource "aws_s3_bucket" "backups" {
  bucket = "${local.common_name}-alf-backups"
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
        kms_master_key_id = module.s3bucket.s3bucket_kms_id
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    enabled = true
    transition {
      days          = local.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = local.expiration_days
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.common_name}-alf-backups"
    },
  )
}

resource "aws_s3_bucket_metric" "backups" {
  bucket = aws_s3_bucket.backups.bucket
  name   = "EntireBucket"
}

