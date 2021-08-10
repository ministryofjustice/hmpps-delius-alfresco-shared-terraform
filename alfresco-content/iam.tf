# task
data "aws_iam_policy_document" "task_policy" {
  statement {
    sid    = "ListAllBuckets"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "allowAccessToStorageBucket"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      local.storage_bucket_arn,
      format("%s/*", local.storage_bucket_arn)
    ]
  }
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
}
