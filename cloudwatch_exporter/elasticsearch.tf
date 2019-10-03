# Run command below to build zip file
# docker-compose -f cloudwatch_exporter/src/docker-compose.yml up --build

locals {
  fn_elk    = "${local.function_name}-elk"
  group_elk = "/aws/lambda/${local.fn_elk}"

}

resource "aws_lambda_function" "elk_lambda" {
  filename         = "${local.lambda_function_payload_file}"
  function_name    = "${local.fn_elk}"
  description      = "${local.fn_elk}"
  role             = "${aws_iam_role.lambda.arn}"
  handler          = "main.lambda_handler"
  depends_on       = ["aws_iam_role.lambda", "aws_cloudwatch_log_group.elk_lambda"]
  runtime          = "python3.7"
  timeout          = "${var.alf_lambda_timeout}"
  tags             = "${merge(local.tags, map("Name", format("%s", local.fn_elk)))}"
  source_code_hash = "${base64sha256(file("${local.lambda_function_payload_file}"))}"
  publish          = true

  environment {
    variables = {
      ARCHIVE_BUCKET    = "${local.logs_bucket_name}"
      ARCHIVE_REGION    = "${local.region}"
      LOG_SEARCH_FILTER = "${data.terraform_remote_state.elk-migration.loggroup_prefix}"
    }
  }
}

resource "aws_cloudwatch_log_group" "elk_lambda" {
  name              = "${local.group_elk}"
  retention_in_days = "${var.cloudwatch_log_retention}"
  kms_key_id        = "${local.kms_arn}"
  tags              = "${merge(local.tags, map("Name", format("%s", local.group_elk)))}"
}

resource "aws_cloudwatch_event_rule" "elk_lambda" {
  name                = "${local.function_name}"
  description         = "Cronlike scheduled Cloudwatch Event for ${local.function_name}"
  schedule_expression = "cron(${var.alf_cron_expression})"
}

resource "aws_cloudwatch_event_target" "elk_lambda" {
  rule      = "${aws_cloudwatch_event_rule.elk_lambda.name}"
  target_id = "${aws_lambda_function.elk_lambda.id}"
  arn       = "${aws_lambda_function.elk_lambda.arn}"
}

resource "aws_lambda_permission" "elk_lambda" {
  statement_id  = "${local.function_name}_AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.elk_lambda.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.elk_lambda.arn}"
}
