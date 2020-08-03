####################################################
# S3 Buckets - Application specific
####################################################

output "region" {
  value = local.region
}

output "s3bucket" {
  value = module.s3bucket.s3bucket
}

output "s3bucket-logs" {
  value = module.s3bucket.s3bucket-logs
}

# KMS Key
output "s3bucket_kms_arn" {
  value = module.s3bucket.s3bucket_kms_arn
}

output "s3bucket_kms_id" {
  value = module.s3bucket.s3bucket_kms_id
}

# cloudtrail
output "s3bucket_cloudtrail_arn" {
  value = module.s3bucket.s3bucket_cloudtrail_arn
}

output "s3bucket_cloudtrail_id" {
  value = module.s3bucket.s3bucket_cloudtrail_id
}

# backups
output "alf_backups_bucket_name" {
  value = aws_s3_bucket.backups.id
}

output "alf_backups_bucket_arn" {
  value = aws_s3_bucket.backups.arn
}

output "elk_backups_bucket_name" {
  value = aws_s3_bucket.elk_backups.id
}

output "elk_backups_bucket_arn" {
  value = aws_s3_bucket.elk_backups.arn
}

output "cloudwatch_archive_bucket_name" {
  value = aws_s3_bucket.logs.id
}

output "cloudwatch_archive_bucket_arn" {
  value = aws_s3_bucket.logs.arn
}

