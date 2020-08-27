# Run command below to build zip file
# docker-compose -f cloudwatch_exporter/src/docker-compose.yml up --build

locals {
  fn_alf    = "${local.function_name}-alf"
  group_alf = "/aws/lambda/${local.function_name}"
}

resource "aws_lambda_function" "lambda" {
  filename      = local.lambda_function_payload_file
  function_name = local.function_name
  description   = local.function_name
  role          = aws_iam_role.lambda.arn
  handler       = "main.lambda_handler"
  depends_on = [
    aws_iam_role.lambda,
    aws_cloudwatch_log_group.lambda,
  ]
  runtime = "python3.7"
  timeout = var.alf_lambda_timeout
  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.function_name)
    },
  )
  source_code_hash = filebase64sha256(local.lambda_function_payload_file)
  publish          = true
  memory_size      = 256

  environment {
    variables = {
      ARCHIVE_BUCKET = local.logs_bucket_name
      ARCHIVE_REGION = local.region
      WAIT_INTERVAL  = 20
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = local.group_alf
  retention_in_days = var.alf_cloudwatch_log_retention
  kms_key_id        = local.kms_arn
  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.group_alf)
    },
  )
}

resource "aws_cloudwatch_event_rule" "lambda" {
  name                = local.function_name
  description         = "Cronlike scheduled Cloudwatch Event for ${local.function_name}"
  schedule_expression = "cron(${var.alf_cron_expression})"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.lambda.name
  target_id = aws_lambda_function.lambda.id
  arn       = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "lambda" {
  statement_id  = "${local.function_name}_AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda.arn
}

