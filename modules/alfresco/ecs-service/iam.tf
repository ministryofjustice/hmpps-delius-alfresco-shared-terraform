# Task execution role for pulling the image, fetching secrets, and pushing logs to cloudwatch
resource "aws_iam_role" "execution" {
  name               = format("%s-execution-role", var.ecs_config["name"])
  assume_role_policy = data.aws_iam_policy_document.execution_assume.json
  description        = format("%s-execution-role", var.ecs_config["name"])
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
      var.ecs_config["config_bucket_arn"]
    ]
  }
  statement {
    sid    = "allowAccessToFluentBitConfigs"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      var.ecs_config["fluentbit_s3_arn"]
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
      format("arn:aws:logs:%s:%s:*", var.ecs_config["region"], var.ecs_config["account_id"])
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
    resources = [
      format("%s", var.ecs_config["log_group_arn"])
    ]
  }
  dynamic "statement" {
    for_each = length(keys(var.secrets)) > 0 ? [""] : []
    content {
      sid       = "Parameters"
      effect    = "Allow"
      actions   = ["ssm:GetParameter", "ssm:GetParameters"]
      resources = values(var.secrets)
    }
  }
}

resource "aws_iam_policy" "execution_policy" {
  name   = format("%s-ecs-execution-policy", var.ecs_config["name"])
  policy = data.aws_iam_policy_document.execution_policy.json
}

resource "aws_iam_role_policy_attachment" "execution_policy_attachment" {
  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.execution_policy.arn
}

# task
resource "aws_iam_role" "task" {
  name               = format("%s-ecs-task-role", var.ecs_config["name"])
  assume_role_policy = data.aws_iam_policy_document.execution_assume.json
  description        = format("%s-ecs-task-role", var.ecs_config["name"])
}

resource "aws_iam_policy" "task_policy" {
  name   = format("%s-ecs-task-policy", var.ecs_config["name"])
  policy = var.task_policy_json
}

resource "aws_iam_role_policy_attachment" "task_policy_attachment" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task_policy.arn
}

