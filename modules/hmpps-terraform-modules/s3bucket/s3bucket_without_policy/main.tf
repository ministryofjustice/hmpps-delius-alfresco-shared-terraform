resource "aws_s3_bucket" "environment" {
  bucket = "${var.s3_bucket_name}-s3bucket"
  acl    = var.acl

  versioning {
    enabled = var.versioning
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

  tags = merge(
    var.tags,
    {
      "Name" = "${var.s3_bucket_name}-s3-bucket"
    },
  )
}

