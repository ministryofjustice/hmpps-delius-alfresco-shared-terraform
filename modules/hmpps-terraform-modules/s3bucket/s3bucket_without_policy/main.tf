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

# The following was run when setting up a new environment (but then commented out again)
#   to allow
#   a) the new env to be set up correctly
#   b) not introduce changes to other environements
# Changes were need to set up a new environment because of the changes in AWS default bucket settings applied after the original environments were set up.
# Ensure that object_ownership is set to override the default (changed in April 2023) to ensure compatibility with existing older buckets for time being.
# # See https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/
# resource "aws_s3_bucket_ownership_controls" "environment" {
#   bucket = aws_s3_bucket.environment.id
#   rule {
#     object_ownership = "ObjectWriter"
#   }
# }

# resource "aws_s3_bucket_acl" "environment" {
#   bucket = aws_s3_bucket.environment.id
#   acl    = var.acl
# }

# # Needed to allow the log-delivery-write canned ACL to be applied
# resource "aws_s3_bucket_public_access_block" "environment" {
#   bucket                  = aws_s3_bucket.environment.id
#   block_public_acls       = false
#   restrict_public_buckets = false
#   ignore_public_acls      = false
#   block_public_policy     = false

# }
