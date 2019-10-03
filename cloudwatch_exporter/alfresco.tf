# Run command below to build zip file
# docker-compose -f cloudwatch_exporter/src/docker-compose.yml up --build

locals {
  fn_alf    = "${local.function_name}-alf"
  group_alf = "/aws/lambda/${local.fn_alf}"

}

resource "aws_lambda_function" "alf_lambda" {
  filename         = "${local.lambda_function_payload_file}"
  function_name    = "${local.fn_alf}"
  description      = "${local.fn_alf}"
  role             = "${aws_iam_role.lambda.arn}"
  handler          = "main.lambda_handler"
  depends_on       = ["aws_iam_role.lambda", "aws_cloudwatch_log_group.alf_lambda"]
  runtime          = "python3.7"
  timeout          = "${var.alf_lambda_timeout}"
  tags             = "${merge(local.tags, map("Name", format("%s", local.fn_alf)))}"
  source_code_hash = "${base64sha256(file("${local.lambda_function_payload_file}"))}"
  publish          = true

  environment {
    variables = {
      ARCHIVE_BUCKET    = "${local.logs_bucket_name}"
      ARCHIVE_REGION    = "${local.region}"
      LOG_SEARCH_FILTER = "${data.terraform_remote_state.asg.asg_loggroup_name}"
    }
  }
}

resource "aws_cloudwatch_log_group" "alf_lambda" {
  name              = "${local.group_alf}"
  retention_in_days = "${var.cloudwatch_log_retention}"
  kms_key_id        = "${local.kms_arn}"
  tags              = "${merge(local.tags, map("Name", format("%s", local.group_alf)))}"
}

resource "aws_cloudwatch_event_rule" "alf_lambda" {
  name                = "${local.function_name}"
  description         = "Cronlike scheduled Cloudwatch Event for ${local.function_name}"
  schedule_expression = "cron(${var.alf_cron_expression})"
}

resource "aws_cloudwatch_event_target" "alf_lambda" {
  rule      = "${aws_cloudwatch_event_rule.alf_lambda.name}"
  target_id = "${aws_lambda_function.alf_lambda.id}"
  arn       = "${aws_lambda_function.alf_lambda.arn}"
}

resource "aws_lambda_permission" "alf_lambda" {
  statement_id  = "${local.function_name}_AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.alf_lambda.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.alf_lambda.arn}"
}
