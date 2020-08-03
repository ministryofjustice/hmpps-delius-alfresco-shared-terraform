output "s3_bucket_arn" {
  value = aws_s3_bucket.environment.arn
}

output "s3_bucket_name" {
  value = aws_s3_bucket.environment.id
}

output "s3_bucket_domain_name" {
  value = aws_s3_bucket.environment.bucket_domain_name
}

