####################################################
# S3 Buckets - Application specific
####################################################

output "region" {
  value = "${local.region}"
}

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

# elasticsearch
output "s3_elasticsearch_bucket" {
  value = "${module.s3_elasticsearch_bucket.s3_bucket_name}"
}

output "s3_elasticsearch_bucket_arn" {
  value = "${module.s3_elasticsearch_bucket.s3_bucket_arn}"
}
