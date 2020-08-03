resource "aws_s3_bucket_policy" "environment" {
  bucket = var.s3_bucket_id
  policy = var.policyfile
}

