resource "aws_cloudwatch_event_rule" "rule" {
  name                = var.target_function["rule_name"]
  description         = "triggers lambda function ${var.target_function["name"]} with payload"
  schedule_expression = "cron(${var.target_function["schedule"]})"
}

resource "aws_cloudwatch_event_target" "rule" {
  rule      = aws_cloudwatch_event_rule.rule.name
  target_id = var.target_function["id"]
  arn       = var.target_function["arn"]
  input     = var.target_function["input"]
}

resource "aws_lambda_permission" "rule" {
  statement_id  = var.target_function["rule_name"]
  action        = "lambda:InvokeFunction"
  function_name = var.target_function["name"]
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rule.arn
}

