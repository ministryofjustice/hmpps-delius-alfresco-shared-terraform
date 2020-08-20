resource "aws_s3_bucket_object" "worker" {
  bucket = local.config-bucket
  key    = "lambda/${local.function_worker}/${filemd5(local.worker_payload_file)}/function.zip"
  source = local.worker_payload_file
  etag   = filemd5(local.worker_payload_file)
}

resource "aws_lambda_function" "worker" {
  function_name = local.function_worker
  description   = local.function_worker
  role          = local.iam_role_arn
  handler       = "main.lambda_handler"
  depends_on = [
    aws_cloudwatch_log_group.worker,
    aws_s3_bucket_object.worker,
  ]
  runtime = "python3.8"
  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.function_worker)
    },
  )
  s3_bucket   = local.config-bucket
  s3_key      = "lambda/${local.function_worker}/${filemd5(local.worker_payload_file)}/function.zip"
  publish     = true
  memory_size = 256
  timeout     = 180

  environment {
    variables = {
      S3_BUCKET_NAME     = local.s3bucket
    }
  }
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = local.logs_worker
  retention_in_days = var.alf_cloudwatch_log_retention
  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.logs_worker)
    },
  )
}

