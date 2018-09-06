# S3 Buckets
output "service_alfresco_s3bucket" {
  value = "${module.s3bucket.s3_bucket_name}"
}

output "service_alfresco_s3bucket-logs" {
  value = "${module.s3bucket-logs.s3_bucket_name}"
}

# KMS Key
output "service_alfresco_s3bucket_kms_arn" {
  value = "${module.kms_key.kms_arn}"
}

output "service_alfresco_s3bucket_kms_id" {
  value = "${module.kms_key.kms_key_id}"
}

# cloudtrail
output "service_alfresco_s3bucket_cloudtrail_arn" {
  value = "${module.cloudtrail.cloudtrail_arn}"
}

output "service_alfresco_s3bucket_cloudtrail_id" {
  value = "${module.cloudtrail.cloudtrail_id}"
}
