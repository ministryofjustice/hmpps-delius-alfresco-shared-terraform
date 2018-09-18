####################################################
# S3 Buckets - Application specific
####################################################

output "s3bucket" {
  value = "${module.s3bucket.s3bucket}"
}

output "s3bucket-logs" {
  value = "${module.s3bucket.s3bucket-logs}"
}

# KMS Key
output "s3bucket_kms_arn" {
  value = "${module.s3bucket.s3bucket_kms_arn}"
}

output "s3bucket_kms_id" {
  value = "${module.s3bucket.s3bucket_kms_id}"
}

# cloudtrail
output "s3bucket_cloudtrail_arn" {
  value = "${module.s3bucket.s3bucket_cloudtrail_arn}"
}

output "s3bucket_cloudtrail_id" {
  value = "${module.s3bucket.s3bucket_cloudtrail_id}"
}
