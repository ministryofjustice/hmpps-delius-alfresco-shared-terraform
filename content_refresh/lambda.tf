### SNS

locals {
  function_name = "AlfSubmitS3Task"
  group_alf     = "/aws/lambda/${local.function_name}"
  payload_file  = "files/s3sync/function.zip"
}

resource "aws_s3_bucket_object" "build_code" {
  bucket = "${local.config-bucket}"
  key    = "lambda/${local.function_name}/${md5(file(local.payload_file))}/function.zip"
  source = "${local.payload_file}"
  etag   = "${md5(file(local.payload_file))}"
}


resource "aws_lambda_function" "content" {
  function_name = "${local.function_name}Copy"
  description   = "${local.function_name}"
  role          = "${local.iam_role_arn}"
  handler       = "task_handler.lambda_handler"
  depends_on    = ["aws_cloudwatch_log_group.lambda", "aws_s3_bucket_object.build_code"]
  runtime       = "python3.7"
  tags          = "${merge(local.tags, map("Name", format("%sCopy", local.function_name)))}"
  s3_bucket     = "${local.config-bucket}"
  s3_key        = "lambda/${local.function_name}/${md5(file(local.payload_file))}/function.zip"
  publish       = true
  memory_size   = 256

  vpc_config {
    subnet_ids         = ["${local.private_subnet_ids}"]
    security_group_ids = ["${local.esadmin_sgs}", "${aws_security_group.redis.id}"]
  }

  environment {
    variables = {
      LOG_GROUP     = "${local.log_group}"
      REDISTOGO_URL = "redis://${aws_elasticache_cluster.redis.cache_nodes.0.address}:${aws_elasticache_cluster.redis.cache_nodes.0.port}"
    }
  }
}

resource "aws_lambda_function" "list" {
  function_name = "${local.function_name}List"
  description   = "${local.function_name}"
  role          = "${local.iam_role_arn}"
  handler       = "list_handler.lambda_handler"
  depends_on    = ["aws_cloudwatch_log_group.lambda", "aws_s3_bucket_object.build_code"]
  runtime       = "python3.7"
  tags          = "${merge(local.tags, map("Name", format("%sList", local.function_name)))}"
  s3_bucket     = "${local.config-bucket}"
  s3_key        = "lambda/${local.function_name}/${md5(file(local.payload_file))}/function.zip"
  publish       = true
  memory_size   = 256

  vpc_config {
    subnet_ids         = ["${local.private_subnet_ids}"]
    security_group_ids = ["${local.esadmin_sgs}", "${aws_security_group.redis.id}"]
  }

  environment {
    variables = {
      LOG_GROUP     = "${local.log_group}"
      REDISTOGO_URL = "redis://${aws_elasticache_cluster.redis.cache_nodes.0.address}:${aws_elasticache_cluster.redis.cache_nodes.0.port}"
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "${local.group_alf}"
  retention_in_days = "${var.alf_cloudwatch_log_retention}"
  tags              = "${merge(local.tags, map("Name", format("%s", local.group_alf)))}"
}
