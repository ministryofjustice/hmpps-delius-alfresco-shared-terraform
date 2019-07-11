# S3 Buckets
output "s3bucket" {
  value = "${module.s3bucket.s3_bucket_name}"
}

output "s3bucket-logs" {
  value = "${module.s3bucket-logs.s3_bucket_name}"
}

# KMS Key
output "s3bucket_kms_arn" {
  value = "${module.kms_key.kms_arn}"
}

output "s3bucket_kms_id" {
  value = "${module.kms_key.kms_key_id}"
}

# cloudtrail
output "s3bucket_cloudtrail_arn" {
  value = "${module.cloudtrail.cloudtrail_arn}"
}

output "s3bucket_cloudtrail_id" {
  value = "${module.cloudtrail.cloudtrail_id}"
}
