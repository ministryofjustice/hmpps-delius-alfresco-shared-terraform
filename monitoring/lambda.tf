### SNS

locals {
  function_name                = "${local.common_name}-notify"
  group_alf                    = "/aws/lambda/${local.function_name}"
  lambda_function_payload_file = "./files/alert_handler/function.zip"
}


resource "aws_sns_topic" "alarm_notification" {
  name = "${local.common_name}-alarm-notification"
}

resource "aws_sns_topic_subscription" "alarm_subscription" {
  count     = "${var.alf_alarms_enabled}"
  topic_arn = "${aws_sns_topic.alarm_notification.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify-ops-slack.arn}"
}

resource "aws_lambda_function" "notify-ops-slack" {
  filename         = "${local.lambda_function_payload_file}"
  function_name    = "${local.function_name}"
  description      = "${local.function_name}"
  role             = "${aws_iam_role.lambda.arn}"
  handler          = "main.lambda_handler"
  depends_on       = ["aws_cloudwatch_log_group.lambda"]
  runtime          = "${var.alf_ops_alerts["runtime"]}"
  tags             = "${merge(local.tags, map("Name", format("%s", local.function_name)))}"
  source_code_hash = "${base64sha256(file("${local.lambda_function_payload_file}"))}"
  publish          = true
  memory_size      = 256

  environment {
    variables = {
      SLACK_CHANNEL_NAME     = "${var.alf_ops_alerts["slack_channel_name"]}"
      LOG_LEVEL              = "${var.alf_ops_alerts["log_level"]}"
      SLACK_MESSAGING_STATUS = "${var.alf_ops_alerts["messaging_status"]}"
      SLACK_EMOJI_ALERT      = "rotating_light"
      SLACK_EMOJI_CRITICAL   = "alert"
      SLACK_EMOJI_WARNING    = "warning"
      SLACK_EMOJI_OK         = "white_check_mark"
      SLACK_API_TOKEN_SSM    = "${var.alf_ops_alerts["ssm_token"]}"
      ENVIRONMENT_NAME       = "${var.environment_name}"
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "${local.group_alf}"
  retention_in_days = "${var.alf_cloudwatch_log_retention}"
  tags              = "${merge(local.tags, map("Name", format("%s", local.group_alf)))}"
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify-ops-slack.arn}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.alarm_notification.arn}"
}
