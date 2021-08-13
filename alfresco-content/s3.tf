resource "aws_s3_bucket" "s3" {
  bucket = format("%s-storage", local.common_name)
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
        kms_master_key_id = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_id
        sse_algorithm     = "aws:kms"
      }
    }
  }
  tags = merge(
    local.tags,
    {
      "Name" = format("%s-storage", local.common_name)
    }
  )
}
