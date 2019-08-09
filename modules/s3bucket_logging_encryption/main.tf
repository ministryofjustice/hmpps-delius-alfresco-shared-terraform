resource "aws_s3_bucket" "environment" {
  bucket = "${var.s3_bucket_name}-s3bucket"
  acl    = "${var.acl}"

  versioning {
    enabled = "${var.versioning}"
  }

  lifecycle {
    prevent_destroy = false
  }

  logging {
    target_bucket = "${var.target_bucket}"
    target_prefix = "${var.target_prefix}"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${var.kms_master_key_id}"
        sse_algorithm     = "${var.sse_algorithm}"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    noncurrent_version_transition {
      days          = "${var.s3_lifecycle_config["noncurrent_version_transition_days"]}"
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      days          = "${var.s3_lifecycle_config["noncurrent_version_transition_glacier_days"]}"
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = "${var.s3_lifecycle_config["noncurrent_version_expiration_days"]}"
    }
  }
  tags = "${merge(var.tags, map("Name", "${var.s3_bucket_name}-s3-bucket"))}"
}
