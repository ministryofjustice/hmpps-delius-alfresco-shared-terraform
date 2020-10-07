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
  function_name = local.function_name
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
  timeout     = 120

  environment {
    variables = {
      ROLE_ARN            = aws_iam_role.elasticsearch.arn
      BUCKET_NAME         = local.elk_bucket_name
      AWS_ES_HOST         = aws_elasticsearch_domain.es.endpoint
      INDICES_UNIT_COUNT  = lookup(local.alf_elk_service_props, "indices_unit_count", 30)
      SNAPSHOT_UNIT_COUNT = lookup(local.alf_elk_service_props, "snapshot_unit_count", 28)
      BACKUP_UNITS_COUNT  = lookup(local.alf_elk_service_props, "backup_units_count", 2)
    }
  }

  vpc_config {
    subnet_ids = flatten(local.private_subnet_ids)
    security_group_ids = [
      aws_security_group.access_es.id,
      data.terraform_remote_state.common.outputs.common_sg_outbound_id,
      data.terraform_remote_state.security-groups.outputs.security_groups_map["mon_jenkins"]
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

module "register_repo" {
  source = "../modules/cloudwatch/rule_trigger_lambda"
  target_function = {
    rule_name = "alf-elasticsearch-register-repo"
    name      = aws_lambda_function.repo.function_name
    id        = aws_lambda_function.repo.id
    arn       = aws_lambda_function.repo.arn
    input     = jsonencode({ "task" = "register-repo" })
    schedule  = lookup(local.alf_elk_service_props, "repo_schedule", "30 18 * * ? *")
  }
}

module "create_snapshot" {
  source = "../modules/cloudwatch/rule_trigger_lambda"
  target_function = {
    rule_name = "alf-elasticsearch-create-snapshot"
    name      = aws_lambda_function.repo.function_name
    id        = aws_lambda_function.repo.id
    arn       = aws_lambda_function.repo.arn
    input     = jsonencode({ "task" = "submit-create-snapshot" })
    schedule  = lookup(local.alf_elk_service_props, "snapshot_schedule", "30 19 * * ? *")
  }
}

module "delete_indices" {
  source = "../modules/cloudwatch/rule_trigger_lambda"
  target_function = {
    rule_name = "alf-elasticsearch-delete-indices"
    name      = aws_lambda_function.repo.function_name
    id        = aws_lambda_function.repo.id
    arn       = aws_lambda_function.repo.arn
    input     = jsonencode({ "task" = "submit-delete-indices-task" })
    schedule  = lookup(local.alf_elk_service_props, "indices_schedule", "30 20 * * ? *")
  }
}

module "delete_snapshots" {
  source = "../modules/cloudwatch/rule_trigger_lambda"
  target_function = {
    rule_name = "alf-elasticsearch-delete-snapshot"
    name      = aws_lambda_function.repo.function_name
    id        = aws_lambda_function.repo.id
    arn       = aws_lambda_function.repo.arn
    input     = jsonencode({ "task" = "submit-delete-snapshot" })
    schedule  = lookup(local.alf_elk_service_props, "delete_schedule", "30 21 * * ? *")
  }
}
