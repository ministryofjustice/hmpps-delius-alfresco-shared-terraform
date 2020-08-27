### SNS

locals {
  function_name = "AlfSubmitS3Task"
  group_alf     = "/aws/lambda/${local.function_name}"
  payload_file  = "files/s3sync/function.zip"
}

resource "aws_s3_bucket_object" "build_code" {
  bucket = local.config-bucket
  key    = "lambda/${local.function_name}/${filemd5(local.payload_file)}/function.zip"
  source = local.payload_file
  etag   = filemd5(local.payload_file)
}

resource "aws_lambda_function" "content" {
  function_name = "${local.function_name}Copy"
  description   = local.function_name
  role          = local.iam_role_arn
  handler       = "task_handler.lambda_handler"
  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_s3_bucket_object.build_code,
  ]
  runtime = "python3.7"
  tags = merge(
    local.tags,
    {
      "Name" = format("%sCopy", local.function_name)
    },
  )
  s3_bucket   = local.config-bucket
  s3_key      = "lambda/${local.function_name}/${filemd5(local.payload_file)}/function.zip"
  publish     = true
  memory_size = 256
  timeout     = 120

  vpc_config {
    subnet_ids         = flatten(local.private_subnet_ids)
    security_group_ids = flatten(local.common_sgs)
  }

  environment {
    variables = {
      LOG_GROUP          = local.log_group
      REDISTOGO_URL      = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}"
      DESTINATION_BUCKET = local.storage_s3bucket
      SOURCE_BUCKET      = local.source_bucket
    }
  }
}

resource "aws_lambda_function" "list" {
  function_name = "${local.function_name}List"
  description   = local.function_name
  role          = local.iam_role_arn
  handler       = "list_handler.lambda_handler"
  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_s3_bucket_object.build_code,
  ]
  runtime = "python3.7"
  tags = merge(
    local.tags,
    {
      "Name" = format("%sList", local.function_name)
    },
  )
  s3_bucket   = local.config-bucket
  s3_key      = "lambda/${local.function_name}/${filemd5(local.payload_file)}/function.zip"
  publish     = true
  memory_size = 256

  vpc_config {
    subnet_ids         = flatten(local.private_subnet_ids)
    security_group_ids = flatten(local.common_sgs)
  }

  environment {
    variables = {
      LOG_GROUP     = local.log_group
      REDISTOGO_URL = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}"
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = local.group_alf
  retention_in_days = var.alf_cloudwatch_log_retention
  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.group_alf)
    },
  )
}

