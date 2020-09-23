### SNS

locals {
  function_name = "AlfElasticSearch"
  group_alf     = "/aws/lambda/${local.function_name}"
  payload_file  = "../functions/aws-elasticsearch/function.zip"
}

resource "aws_s3_bucket_object" "build_code" {
  bucket = local.config-bucket
  key    = "lambda/${local.function_name}/${filemd5(local.payload_file)}/function.zip"
  source = local.payload_file
  etag   = filemd5(local.payload_file)
}

resource "aws_lambda_function" "repo" {
  function_name = "${local.function_name}"
  description   = local.function_name
  role          = module.es-lambda.iamrole_arn
  handler       = "main.lambda_handler"
  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_s3_bucket_object.build_code,
  ]
  runtime = "python3.7"
  tags = merge(
    local.tags,
    {
      "Name" = local.function_name
    },
  )
  s3_bucket   = local.config-bucket
  s3_key      = "lambda/${local.function_name}/${filemd5(local.payload_file)}/function.zip"
  publish     = true
  memory_size = 256
  timeout     = 30

  environment {
    variables = {
      ROLE_ARN    = aws_iam_role.elasticsearch.arn
      BUCKET_NAME = local.elk_bucket_name
      AWS_ES_HOST = "https://${aws_elasticsearch_domain.es.endpoint}"
    }
  }

  vpc_config {
    subnet_ids = flatten(local.private_subnet_ids)
    security_group_ids = [
      aws_security_group.access_es.id,
      data.terraform_remote_state.common.outputs.common_sg_outbound_id
    ]
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

