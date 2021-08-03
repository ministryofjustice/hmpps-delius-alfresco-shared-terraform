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

# Task execution role for pulling the image, fetching secrets, and pushing logs to cloudwatch
resource "aws_iam_role" "execution" {
  name               = format("%s-execution-role", local.application_name)
  assume_role_policy = data.aws_iam_policy_document.execution_assume.json
  description        = format("%s-execution-role", local.application_name)
}

data "aws_iam_policy_document" "execution_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "execution_policy" {
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
  statement {
    sid    = "ECR"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "Scaling"
    effect = "Allow"
    actions = [
      "application-autoscaling:*",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm"
    ]
    resources = [
      format("arn:aws:logs:%s:%s:*", local.region, local.account_id)
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "execution_policy" {
  name   = format("%s-ecs-execution-policy", local.application_name)
  policy = data.aws_iam_policy_document.execution_policy.json
}

resource "aws_iam_role_policy_attachment" "execution_policy_attachment" {
  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.execution_policy.arn
}

# task
resource "aws_iam_role" "task" {
  name               = format("%s-ecs-task-role", local.application_name)
  assume_role_policy = data.aws_iam_policy_document.execution_assume.json
  description        = format("%s-ecs-task-role", local.application_name)
}

resource "aws_iam_policy" "task_policy" {
  name   = format("%s-ecs-task-policy", local.application_name)
  policy = data.aws_iam_policy_document.task_policy.json
}

resource "aws_iam_role_policy_attachment" "task_policy_attachment" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task_policy.arn
}

