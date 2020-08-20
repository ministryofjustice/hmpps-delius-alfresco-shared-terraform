resource "aws_s3_bucket_object" "submit" {
  bucket = local.config-bucket
  key    = "lambda/${local.function_submitter}/${filemd5(local.submit_payload_file)}/function.zip"
  source = local.submit_payload_file
  etag   = filemd5(local.submit_payload_file)
}

resource "aws_lambda_function" "submit" {
  function_name = local.function_submitter
  description   = local.function_submitter
  role          = local.iam_role_arn
  handler       = "main.lambda_handler"
  depends_on = [
    aws_cloudwatch_log_group.submit,
    aws_s3_bucket_object.submit,
  ]
  runtime = "python3.8"
  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.function_submitter)
    },
  )
  s3_bucket   = local.config-bucket
  s3_key      = "lambda/${local.function_submitter}/${filemd5(local.submit_payload_file)}/function.zip"
  publish     = true
  memory_size = 128
  timeout     = 180

  environment {
    variables = {
      TARGET_FUNCTION_NAME     = aws_lambda_function.worker.function_name
    }
  }
}

resource "aws_cloudwatch_log_group" "submit" {
  name              = local.logs_submit
  retention_in_days = var.alf_cloudwatch_log_retention
  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.logs_submit)
    },
  )
}

