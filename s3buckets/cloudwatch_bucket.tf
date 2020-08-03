#-------------------------------------------
### S3 bucket for logs archive
#--------------------------------------------

resource "aws_s3_bucket" "logs" {
  bucket = "${local.common_name}-alf-logs"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
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
      days          = local.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = local.expiration_days
    }

    noncurrent_version_transition {
      days          = var.alf_backups_config["noncurrent_version_transition_days"]
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      days          = var.alf_backups_config["noncurrent_version_transition_glacier_days"]
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = var.alf_backups_config["noncurrent_version_expiration_days"]
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.common_name}-alf-logs"
    },
  )
}

resource "aws_s3_bucket_metric" "logs" {
  bucket = aws_s3_bucket.logs.bucket
  name   = "EntireBucket"
}

data "template_file" "logs" {
  template = file("../policies/cloudwatch_logs.json")

  vars = {
    region      = local.region
    logs_bucket = aws_s3_bucket.logs.arn
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.template_file.logs.rendered
}

