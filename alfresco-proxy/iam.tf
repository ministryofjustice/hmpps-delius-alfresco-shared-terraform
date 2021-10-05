# task
data "aws_iam_policy_document" "task_policy" {
  statement {
    sid    = "AllowUseOfKmsKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      local.storage_kms_arn
    ]
  }
  statement {
    sid    = "PushLogsToES"
    effect = "Allow"
    actions = [
      "firehose:PutRecordBatch",
      "es:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "allowAccessToConfigBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation"
    ]
    resources = [
      local.config_bucket_arn
    ]
  }
  statement {
    sid    = "allowAccessToFluentBitConfigs"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      format("%s/%s", local.config_bucket_arn, local.fluentbit_s3_path)
    ]
  }
}
