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
}